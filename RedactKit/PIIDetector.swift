//
// PIIDetector.swift
// RedactKit
//
// Created by Supachod Trakansirorut on 30/8/25.
//
import Foundation
import CoreML
import NaturalLanguage
import Tokenizers

// Step 1: Custom tokenization (regex based) with offsets
struct TokenOffset {
    let token: String
    let start: Int
    let end: Int
}

// MARK: - PII Detection Models
struct PIIEntity {
    let text: String
    let label: String
    let startIndex: Int
    let endIndex: Int
    let confidence: Float = 0.0
}

enum PIILabel: String, CaseIterable {
    case outside = "O"
    case beginPerson = "B-PER"
    case insidePerson = "I-PER"
    case beginEmail = "B-EMAIL"
    case beginPhone = "B-PHONE"
    case insidePhone = "I-PHONE"
    case beginAddress = "B-ADDR"
    case insideAddress = "I-ADDR"
    case beginSSN = "B-SSN"
    case insideSSN = "I-SSN"
    case beginCreditCard = "B-CC"
    case beginDate = "B-DATE"
    case insideDate = "I-DATE"
    
    var displayName: String {
        switch self {
        case .beginPerson, .insidePerson: return "Person"
        case .beginEmail: return "Email"
        case .beginPhone, .insidePhone: return "Phone"
        case .beginAddress, .insideAddress: return "Address"
        case .beginSSN, .insideSSN: return "SSN"
        case .beginCreditCard: return "Credit Card"
        case .beginDate, .insideDate: return "Date"
        case .outside: return "None"
        }
    }
}

@MainActor
class PIIDetectionService: ObservableObject {
    private var model: MLModel?
    private var tokenizer: Tokenizer?
    private let labels = ["O", "B-PER", "I-PER", "B-EMAIL", "B-PHONE", "I-PHONE", "B-ADDR", "I-ADDR", "B-SSN", "I-SSN", "B-CC", "B-DATE", "I-DATE"]
    
    @Published var isLoading = false
    
    init() {
        Task {
            await loadModel()
            await loadTokenizer()
        }
    }
    
    private func loadModel() async {
        guard let url = Bundle.main.url(forResource: "PIIDetectionModel", withExtension: "mlmodelc") else { return }
        model = try? MLModel(contentsOf: url)
        print("✅ Model loaded")
    }
    
    private func loadTokenizer() async {
//        tokenizer = try? await BertTokenizer
        tokenizer = try? await AutoTokenizer.from(pretrained: "boltuix/NeuroBERT-Mini")
        print("✅ Tokenizer loaded")
    }

    func tokenizeTextWithOffsets(_ text: String) -> [TokenOffset] {
        let regex = try! NSRegularExpression(pattern: #"[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}|\w+|[.,@-]"#)
        let matches = regex.matches(in: text, range: NSRange(text.startIndex..., in: text))
        return matches.map {
            let start = text.index(text.startIndex, offsetBy: $0.range.lowerBound)
            let end = text.index(text.startIndex, offsetBy: $0.range.upperBound)
            return TokenOffset(token: String(text[start..<end]), start: $0.range.lowerBound, end: $0.range.upperBound)
        }
    }
    
    func convertToSwiftArray(_ multiArray: MLMultiArray) -> [Int] {
            let count = multiArray.count

            // Create an empty array to store the converted values.
            var swiftArray = [Int]()

            // Iterate over each element in the MLMultiArray and append it to the swiftArray.
            for i in 0..<count {
                let value = multiArray[i].intValue
                swiftArray.append(value)
            }

            return swiftArray
        }
    
    func detectPII(in text: String) async -> [PIIEntity] {
        guard let model = model, let tokenizer = tokenizer else { return [] }
        
        isLoading = true
        defer { isLoading = false }
        
        
        
        let firstTokensWithOffsets: [TokenOffset] = tokenizeTextWithOffsets(text)
        
        var allSubTokens: [String] = []
        var subTokenToOriginalIndex: [Int] = []  // maps subtoken idx → original token idx
        
        // Step 2: Tokenize each token into subtokens, track mapping
        for (i, t) in firstTokensWithOffsets.enumerated() {
            let subTokens = tokenizer.tokenize(text: t.token)
            allSubTokens.append(contentsOf: subTokens)
            subTokenToOriginalIndex.append(contentsOf: Array(repeating: i, count: subTokens.count))
        }
        
        // Step 3: Encode subtokens to IDs
        var ids: [Int] = []
        for token in allSubTokens {
            ids.append(contentsOf: tokenizer.encode(text: token))
        }
        
        print(allSubTokens)
        print(ids)
        
        // Step 4: Pad to max length (128)
        let paddedIds = Array(ids.prefix(128)) + Array(repeating: 0, count: max(0, 128 - ids.count))
        let paddedMask = Array(repeating: 1, count: min(ids.count, 128)) + Array(repeating: 0, count: max(0, 128 - ids.count))
        
        do {
            // Step 5: Build MLMultiArray inputs
            let inputIds = try MLMultiArray(shape: [1, 128], dataType: .int32)
            let attentionMask = try MLMultiArray(shape: [1, 128], dataType: .int32)
            for i in 0..<128 {
                inputIds[i] = NSNumber(value: paddedIds[i])
                attentionMask[i] = NSNumber(value: paddedMask[i])
            }
            
            // Step 6: Run model
            let input = try MLDictionaryFeatureProvider(dictionary: [
                "input_ids": MLFeatureValue(multiArray: inputIds),
                "attention_mask": MLFeatureValue(multiArray: attentionMask)
            ])
            
            let prediction = try await model.prediction(from: input)
            guard let predictions = prediction.featureValue(for: "predictions")?.multiArrayValue else { return [] }
            let predictionsArray = convertToSwiftArray(predictions)
            print(predictionsArray)
            // Step 7: Aggregate predictions for original tokens
            var tokenPredictions: [String] = Array(repeating: "O", count: firstTokensWithOffsets.count)
            for (subIdx, origIdx) in subTokenToOriginalIndex.enumerated() {
                guard subIdx < predictionsArray.count else { continue }
                let predLabel = labels[predictionsArray[subIdx]]
                if predLabel != "O" {
                    tokenPredictions[origIdx] = predLabel  // take last or first subtoken prediction
                }
            }
            
            // Step 8: Build PIIEntity with original offsets
            var entities: [PIIEntity] = []
            for (i, tokenOffset) in firstTokensWithOffsets.enumerated() {
                let label = tokenPredictions[i]
                if label != "O" {
                    let entity = PIIEntity(
                        text: String(text[text.index(text.startIndex, offsetBy: tokenOffset.start)..<text.index(text.startIndex, offsetBy: tokenOffset.end)]),
                        label: label,
                        startIndex: tokenOffset.start,
                        endIndex: tokenOffset.end
                    )
                    entities.append(entity)
                }
            }
            
            let merged = mergeEntities(entities)
            printResults(merged, text: text)
            return merged
            
        } catch {
            print("Error: \(error)")
            return []
        }
    }
    
    private func isValidPII(token: String, labelIndex: Int) -> Bool {
        let clean = token.trimmingCharacters(in: .punctuationCharacters)
        guard clean.count >= 2 else { return false }
        
        switch labelIndex {
        case 1, 2: // Person
            return clean.first?.isUppercase == true || clean.contains("@") || clean.contains("_")
        case 3: // Email
            return clean.contains("@")
        case 4, 5: // Phone
            return clean.filter { $0.isNumber }.count >= 7
        case 6, 7: // Address
            return clean.lowercased().contains("street") || clean.lowercased().contains("singapore") || clean.contains("#")
        case 8, 9: // SSN
            return clean.filter { $0.isNumber }.count >= 6 && clean.filter { $0.isLetter }.count >= 1
        case 10: // Credit Card
            return clean.filter { $0.isNumber }.count >= 12
        case 11, 12: // Date
            return clean.contains("-") || clean.contains("/")
        default:
            return false
        }
    }
    
    private func mergeEntities(_ entities: [PIIEntity]) -> [PIIEntity] {
        guard !entities.isEmpty else { return [] }
        
        var mergedEntities: [PIIEntity] = []
        var currentEntity: PIIEntity?
        
        for entity in entities {
            guard let label = PIILabel(rawValue: entity.label) else {
                // Skip invalid labels
                continue
            }
            
            // Skip "O" (Outside) labels
            if label == .outside {
                // If we have a current entity being built, finalize it
                if let current = currentEntity {
                    mergedEntities.append(current)
                    currentEntity = nil
                }
                continue
            }
            
            // Check if this is a Begin label
            if isBeginLabel(label) {
                // If we have a current entity being built, finalize it
                if let current = currentEntity {
                    mergedEntities.append(current)
                }
                
                // Start a new entity
                currentEntity = PIIEntity(
                    text: entity.text,
                    label: label.displayName,
                    startIndex: entity.startIndex,
                    endIndex: entity.endIndex
                )
            }
            // Check if this is an Inside label that continues the current entity
            else if isInsideLabel(label),
                    let current = currentEntity,
                    canCombine(currentLabel: current.label, withInsideLabel: label) {
                
                // Extend the current entity
                currentEntity = PIIEntity(
                    text: current.text + entity.text,
                    label: current.label, // Keep the display name
                    startIndex: current.startIndex,
                    endIndex: entity.endIndex
                )
            }
            else {
                // This Inside label doesn't match the current entity or no current entity
                // Finalize current entity if exists
                if let current = currentEntity {
                    mergedEntities.append(current)
                }
                
                // Treat this Inside label as a standalone entity (edge case)
                currentEntity = PIIEntity(
                    text: entity.text,
                    label: label.displayName,
                    startIndex: entity.startIndex,
                    endIndex: entity.endIndex
                )
            }
        }
        
        // Don't forget to add the last entity if it exists
        if let current = currentEntity {
            mergedEntities.append(current)
        }
        
        return mergedEntities
    }

    private func isBeginLabel(_ label: PIILabel) -> Bool {
        switch label {
        case .beginPerson, .beginEmail, .beginPhone, .beginAddress,
             .beginSSN, .beginCreditCard, .beginDate:
            return true
        default:
            return false
        }
    }

    private func isInsideLabel(_ label: PIILabel) -> Bool {
        switch label {
        case .insidePerson, .insidePhone, .insideAddress,
             .insideSSN, .insideDate:
            return true
        default:
            return false
        }
    }

    private func canCombine(currentLabel: String, withInsideLabel insideLabel: PIILabel) -> Bool {
        switch (currentLabel, insideLabel) {
        case ("Person", .insidePerson),
             ("Phone", .insidePhone),
             ("Address", .insideAddress),
             ("SSN", .insideSSN),
             ("Date", .insideDate):
            return true
        default:
            return false
        }
    }

    
    private func printResults(_ entities: [PIIEntity], text: String) {
        print("\n🔍 PII Detection Results:")
        if entities.isEmpty {
            print("✅ No PII detected")
        } else {
            for entity in entities {
                let type = entity.label.replacingOccurrences(of: "B-", with: "").replacingOccurrences(of: "I-", with: "")
                print("🚨 \(type): '\(entity.text)' (Confidence: \(String(format: "%.2f", entity.confidence)))")
            }
        }
    }
}
