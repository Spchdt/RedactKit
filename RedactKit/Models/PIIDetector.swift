import Foundation
import CoreML
import NaturalLanguage
import Tokenizers

func detectPIIWithRegex(in text: String) -> [String] {
    let patterns = [
        "[A-Z0-9._%+-]+@[A-Z0-9.-]+\\.[A-Z]{2,}", 
        "\\(?\\d{3}\\)?[-\\s]?\\d{3}[-\\s]?\\d{4}(?:x\\d+)?",
        "\\d{3}-\\d{2}-\\d{4}",
        "\\b\\d{4}[\\s-]?\\d{4}[\\s-]?\\d{4}[\\s-]?\\d{3,4}\\b",
        "\\d{4}-\\d{2}-\\d{2}|\\d{2}/\\d{2}/\\d{4}|\\d{2}-\\d{2}-\\d{4}",
        "AKIA[0-9A-Z]{16}",
        "sk-[A-Za-z0-9]{48}",
        "ghp_[A-Za-z0-9]{36}",
        "(sk_live_|pk_test_)[A-Za-z0-9]{24}",
        "\\b[A-Za-z0-9]{32,64}\\b"
    ]
    
    var detectedEntities: [String] = []
    
    for (index, pattern) in patterns.enumerated() {
        if let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) {
            let range = NSRange(text.startIndex..<text.endIndex, in: text)
            let matches = regex.matches(in: text, options: [], range: range)
            
            for match in matches {
                if let matchRange = Range(match.range, in: text) {
                    let matchedText = String(text[matchRange])
                    let patternType = getPatternType(for: index)
                    detectedEntities.append("\(patternType): '\(matchedText)'")
                }
            }
        }
    }
    
    return detectedEntities
}

private func getPatternType(for index: Int) -> String {
    switch index {
    case 0: return "Email"
    case 1: return "Phone"
    case 2: return "SSN"
    case 3: return "Credit Card"
    case 4: return "Date"
    case 5: return "AWS Key"
    case 6: return "OpenAI Key"
    case 7: return "GitHub Token"
    case 8: return "Stripe Key"
    case 9: return "Generic API Key"
    default: return "Unknown"
    }
}

struct TokenOffset {
    let token: String
    let start: Int
    let end: Int
}

struct PIIEntity {
    let text: String
    let label: String
    let startIndex: Int
    let endIndex: Int
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
    }
    
    private func loadTokenizer() async {
        do {
            tokenizer = try await AutoTokenizer.from(pretrained: "boltuix/NeuroBERT-Mini")
            
        } catch {
            tokenizer = nil
        }
    }

    func tokenizeTextWithOffsets(_ text: String) -> ([Int], [Int], [TokenOffset]) {
        guard let tokenizer = tokenizer else { 
            return ([], [], [])
        }
        
        let tokenIds = tokenizer.encode(text: text)
        let attentionMask = Array(repeating: 1, count: tokenIds.count)
        
        var tokenOffsets: [TokenOffset] = []
        var currentPos = 0
        
        let startIdx = tokenIds.first == 101 ? 1 : 0
        let endIdx = tokenIds.last == 102 ? tokenIds.count - 1 : tokenIds.count
        
        if startIdx == 1 {
            tokenOffsets.append(TokenOffset(token: "[CLS]", start: -1, end: -1))
        }
        
        for i in startIdx..<endIdx {
            let tokenId = tokenIds[i]
            let tokenText = tokenizer.decode(tokens: [tokenId])
            
            let cleanTokenText = tokenText.replacingOccurrences(of: " ", with: "")
                .replacingOccurrences(of: "##", with: "")
            
            if !cleanTokenText.isEmpty {
                let remainingText = String(text.dropFirst(currentPos))
                
                if let range = remainingText.range(of: cleanTokenText, options: [.caseInsensitive]) {
                    let relativeStart = remainingText.distance(from: remainingText.startIndex, to: range.lowerBound)
                    let relativeEnd = remainingText.distance(from: remainingText.startIndex, to: range.upperBound)
                    
                    let absoluteStart = currentPos + relativeStart
                    let absoluteEnd = currentPos + relativeEnd
                    
                    tokenOffsets.append(TokenOffset(
                        token: String(text[text.index(text.startIndex, offsetBy: absoluteStart)..<text.index(text.startIndex, offsetBy: absoluteEnd)]),
                        start: absoluteStart,
                        end: absoluteEnd
                    ))
                    
                    currentPos = absoluteEnd
                } else {
                    var found = false
                    for char in cleanTokenText {
                        if let charRange = remainingText.range(of: String(char)) {
                            let relativeStart = remainingText.distance(from: remainingText.startIndex, to: charRange.lowerBound)
                            let absoluteStart = currentPos + relativeStart
                            let absoluteEnd = absoluteStart + 1
                            
                            tokenOffsets.append(TokenOffset(
                                token: String(char),
                                start: absoluteStart,
                                end: absoluteEnd
                            ))
                            
                            currentPos = absoluteEnd
                            found = true
                            break
                        }
                    }
                    
                    if !found {
                        tokenOffsets.append(TokenOffset(token: cleanTokenText, start: -1, end: -1))
                    }
                }
            } else {
                tokenOffsets.append(TokenOffset(token: "[SPECIAL]", start: -1, end: -1))
            }
        }
        
        if endIdx < tokenIds.count {
            tokenOffsets.append(TokenOffset(token: "[SEP]", start: -1, end: -1))
        }
        
        return (tokenIds, attentionMask, tokenOffsets)
    }
    
    func convertToSwiftArray(_ multiArray: MLMultiArray) -> [Int] {
            let count = multiArray.count

            var swiftArray = [Int]()

            for i in 0..<count {
                let value = multiArray[i].intValue
                swiftArray.append(value)
            }

            return swiftArray
        }
    
    func detectPII(in text: String) async -> [PIIEntity] {
        guard let model = model else { return [] }
        
        let regexResults = detectPIIWithRegex(in: text)
        
        isLoading = true
        defer { isLoading = false }
        
        let (tokenIds, attentionMask, tokenOffsets) = tokenizeTextWithOffsets(text)
        
        guard !tokenIds.isEmpty else { 
            return []
        }
        
        let maxLength = 128
        let paddedIds = Array(tokenIds.prefix(maxLength)) + Array(repeating: 0, count: max(0, maxLength - tokenIds.count))
        let paddedMask = Array(attentionMask.prefix(maxLength)) + Array(repeating: 0, count: max(0, maxLength - attentionMask.count))
        
        
        do {
            let inputIds = try MLMultiArray(shape: [1, NSNumber(value: maxLength)], dataType: .int32)
            let attentionMaskArray = try MLMultiArray(shape: [1, NSNumber(value: maxLength)], dataType: .int32)
            
            for i in 0..<maxLength {
                inputIds[i] = NSNumber(value: paddedIds[i])
                attentionMaskArray[i] = NSNumber(value: paddedMask[i])
            }
            
            let input = try MLDictionaryFeatureProvider(dictionary: [
                "input_ids": MLFeatureValue(multiArray: inputIds),
                "attention_mask": MLFeatureValue(multiArray: attentionMaskArray)
            ])
            
            let prediction = try await model.prediction(from: input)
            guard let predictions = prediction.featureValue(for: "predictions")?.multiArrayValue else { 
                return []
            }
            let predictionsArray = convertToSwiftArray(predictions)
            
            var entities: [PIIEntity] = []
            let actualTokenCount = min(tokenIds.count, maxLength)
            
            for i in 0..<actualTokenCount {
                guard i < predictionsArray.count && i < tokenOffsets.count else { continue }
                
                let predictionIndex = predictionsArray[i]
                guard predictionIndex < labels.count else { continue }
                
                let label = labels[predictionIndex]
                let offset = tokenOffsets[i]
                
                
                if label != "O" && offset.start >= 0 && offset.end > offset.start {
                    let entity = PIIEntity(
                        text: offset.token,
                        label: label,
                        startIndex: offset.start,
                        endIndex: offset.end
                    )
                    entities.append(entity)
                }
            }
            
            let merged = mergeEntities(entities)
            let finalEntities = reconstructEntityText(merged, from: text)
            let hybridEntities = combineRegexAndMLResults(regexResults: regexResults, mlEntities: finalEntities, originalText: text)

            return hybridEntities
            
        } catch {
            return []
        }
    }

    
    private func isValidPII(token: String, labelIndex: Int) -> Bool {
        let clean = token.trimmingCharacters(in: .punctuationCharacters)
        guard clean.count >= 2 else { return false }
        
        switch labelIndex {
        case 1, 2:
            return clean.first?.isUppercase == true || clean.contains("@") || clean.contains("_")
        case 3:
            return clean.contains("@")
        case 4, 5:
            return clean.filter { $0.isNumber }.count >= 7
        case 6, 7:
            return clean.lowercased().contains("street") || clean.lowercased().contains("singapore") || clean.contains("#")
        case 8, 9:
            return clean.filter { $0.isNumber }.count >= 6 && clean.filter { $0.isLetter }.count >= 1
        case 10:
            return clean.filter { $0.isNumber }.count >= 12
        case 11, 12:
            return clean.contains("-") || clean.contains("/")
        default:
            return false
        }
    }

    private func reconstructEntityText(_ entities: [PIIEntity], from originalText: String) -> [PIIEntity] {
        return entities.compactMap { entity in
            guard entity.startIndex >= 0 && 
                  entity.endIndex <= originalText.count && 
                  entity.startIndex < entity.endIndex else {
                return nil
            }
            
            let startIdx = originalText.index(originalText.startIndex, offsetBy: entity.startIndex)
            let endIdx = originalText.index(originalText.startIndex, offsetBy: entity.endIndex)
            let actualText = String(originalText[startIdx..<endIdx]).trimmingCharacters(in: .whitespaces)
            
            if !isValidEntityContent(text: actualText, entityType: entity.label) {
                return nil
            }
        
            return PIIEntity(
                text: actualText,
                label: entity.label,
                startIndex: entity.startIndex,
                endIndex: entity.endIndex
            )
        }
    }
    
    private func isValidEntityContent(text: String, entityType: String) -> Bool {
        let cleanText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        
        switch entityType {
        case "Person":
            return cleanText.count >= 3 &&
                   cleanText.rangeOfCharacter(from: .letters) != nil &&
                   !cleanText.lowercased().hasPrefix("nders") &&
                   !cleanText.lowercased().hasSuffix("nders")
        case "Phone":
            return cleanText.count >= 5 &&
                   cleanText.filter { $0.isNumber }.count >= 3
        case "SSN":
            let digitCount = cleanText.filter { $0.isNumber }.count
            return cleanText.count >= 3 &&
                   digitCount >= 2 &&
                   !cleanText.hasPrefix(")") && !cleanText.hasSuffix("(") &&
                   !cleanText.contains(")") && !cleanText.contains("(") &&
                   digitCount >= Int(Double(cleanText.count) * 0.4)
        case "Email":
            return cleanText.count >= 3 &&
                   (cleanText.contains("@") || cleanText.rangeOfCharacter(from: .letters) != nil)
        case "Address":
            return cleanText.count >= 5 &&
                   cleanText.rangeOfCharacter(from: .letters) != nil
        case "Credit Card":
            return cleanText.filter { $0.isNumber }.count >= 3
        default:
            return cleanText.count >= 2
        }
    }
    
    private func mergeEntities(_ entities: [PIIEntity]) -> [PIIEntity] {
        guard !entities.isEmpty else { return [] }
        
        let sortedEntities = entities.sorted { $0.startIndex < $1.startIndex }
        
        var mergedEntities: [PIIEntity] = []
        var i = 0
        
        while i < sortedEntities.count {
            let entity = sortedEntities[i]
            guard let label = PIILabel(rawValue: entity.label) else {
                i += 1
                continue
            }
            
            if label == .outside {
                i += 1
                continue
            }
            
            let currentStartIndex = entity.startIndex
            var currentEndIndex = entity.endIndex
            var currentDisplayName = label.displayName
            
            var j = i + 1
            while j < sortedEntities.count {
                let nextEntity = sortedEntities[j]
                guard let nextLabel = PIILabel(rawValue: nextEntity.label) else { break }
                
                let gap = nextEntity.startIndex - currentEndIndex
                let maxAllowedGap = getMaxGapForEntityType(currentDisplayName)
                
                let shouldMerge = shouldMergeEntities(
                    current: currentDisplayName,
                    next: nextLabel.displayName,
                    gap: gap,
                    maxGap: maxAllowedGap
                )
                
                if shouldMerge {
                    currentEndIndex = nextEntity.endIndex
                    if isMoreSpecificEntityType(nextLabel.displayName, than: currentDisplayName) {
                        currentDisplayName = nextLabel.displayName
                    }
                    j += 1
                } else {
                    break
                }
            }
            
            let entityLength = currentEndIndex - currentStartIndex
            if shouldKeepEntity(entityType: currentDisplayName, length: entityLength) {
                let mergedEntity = PIIEntity(
                    text: "",
                    label: currentDisplayName,
                    startIndex: currentStartIndex,
                    endIndex: currentEndIndex
                )
                mergedEntities.append(mergedEntity)
            }
            
            i = j
        }
        
        return mergedEntities
    }
    
    private func shouldMergeEntities(current: String, next: String, gap: Int, maxGap: Int) -> Bool {
        if gap > maxGap {
            return false
        }
        
        if current == next {
            return true
        }
        
        switch (current, next) {
        case ("Email", "Person"):
            return gap <= 5
        case ("Person", "Email"):
            return gap <= 5
        case ("SSN", "Phone"):
            return false
        case ("Phone", "SSN"):
            return false
        case ("Credit Card", "Phone"):
            return gap <= 3
        case ("Phone", "Credit Card"):
            return gap <= 3
        default:
            return false
        }
    }
    
    private func isMoreSpecificEntityType(_ type1: String, than type2: String) -> Bool {
        if type1 == "Email" && type2 == "Person" {
            return true
        }
        if type1 == "Credit Card" && type2 == "Phone" {
            return true
        }
        return false
    }
    
    private func getMaxGapForEntityType(_ entityType: String) -> Int {
        switch entityType {
        case "SSN":
            return 10
        case "Phone":
            return 15
        case "Credit Card":
            return 8
        case "Date":
            return 3
        case "Address":
            return 20
        case "Person":
            return 8
        case "Email":
            return 3
        default:
            return 5
        }
    }
    
    private func shouldKeepEntity(entityType: String, length: Int) -> Bool {
        switch entityType {
        case "SSN":
            return length >= 5
        case "Phone":
            return length >= 5
        case "Credit Card":
            return length >= 3
        case "Email":
            return length >= 3
        case "Person":
            return length >= 4
        case "Date":
            return length >= 6
        case "Address":
            return length >= 8
        default:
            return length >= 3
        }
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
    
    func getPIIMapping(from text: String) async -> [(String, String)] {
        let entities = await detectPII(in: text)
        var redactionArray: [(String, String)] = []
        if !entities.isEmpty {
            for entity in entities {
                let type = entity.label.replacingOccurrences(of: "B-", with: "").replacingOccurrences(of: "I-", with: "")
                redactionArray.append((entity.text, "[\(type)]"))
            }
        }
        return redactionArray
    }
    
    private func redactPII(in text: String, entities: [PIIEntity]) -> String {
        var redactedText = text
        
        let sortedEntities = entities.sorted { $0.startIndex > $1.startIndex }
        
        for entity in sortedEntities {
            let startIndex = text.index(text.startIndex, offsetBy: entity.startIndex)
            let endIndex = text.index(text.startIndex, offsetBy: entity.endIndex)
            let redactionText = "[\(entity.label)]"
            
            redactedText.replaceSubrange(startIndex..<endIndex, with: redactionText)
        }
        
        return redactedText
    }
    
    private func combineRegexAndMLResults(regexResults: [String], mlEntities: [PIIEntity], originalText: String) -> [PIIEntity] {
        var hybridEntities: [PIIEntity] = []
        
        var regexEntities: [PIIEntity] = []
        for result in regexResults {
            if let entity = parseRegexResult(result, in: originalText) {
                regexEntities.append(entity)
            }
        }
        
        
        let entityTypes = Set(regexEntities.map { $0.label } + mlEntities.map { $0.label })
        
        for entityType in entityTypes {
            let regexForType = regexEntities.filter { $0.label == entityType }
            let mlForType = mlEntities.filter { $0.label == entityType }
            
            let bestEntities = chooseBestEntitiesForType(
                entityType: entityType,
                regexEntities: regexForType,
                mlEntities: mlForType,
                originalText: originalText
            )
            
            hybridEntities.append(contentsOf: bestEntities)
        }
        
        
        let finalEntities = removeDuplicatesAndOverlaps(hybridEntities)
        
        return finalEntities
    }
    
    private func parseRegexResult(_ result: String, in text: String) -> PIIEntity? {
        let parts = result.components(separatedBy: ": '")
        guard parts.count == 2 else { return nil }
        
        let type = parts[0]
        let entityText = String(parts[1].dropLast())
        
        if let range = text.range(of: entityText) {
            let startIndex = text.distance(from: text.startIndex, to: range.lowerBound)
            let endIndex = text.distance(from: text.startIndex, to: range.upperBound)
            
            return PIIEntity(
                text: entityText,
                label: type,
                startIndex: startIndex,
                endIndex: endIndex
            )
        }
        
        return nil
    }
    
    private func chooseBestEntitiesForType(
        entityType: String,
        regexEntities: [PIIEntity],
        mlEntities: [PIIEntity],
        originalText: String
    ) -> [PIIEntity] {
        switch entityType {
        case "Email":
            return regexEntities.isEmpty ? mlEntities : regexEntities
            
        case "Phone":
            return regexEntities.isEmpty ? mlEntities : regexEntities
            
        case "SSN":
            return regexEntities.isEmpty ? mlEntities : regexEntities
            
        case "Credit Card":
            return regexEntities.isEmpty ? mlEntities : regexEntities
            
        case "Date":
            return combineDateEntities(regexEntities: regexEntities, mlEntities: mlEntities)
            
        case "Person":
            return mlEntities.isEmpty ? regexEntities : mlEntities
            
        case "Address":
            return mlEntities.isEmpty ? regexEntities : mlEntities
            
        default:
            return regexEntities.isEmpty ? mlEntities : regexEntities
        }
    }
    
    private func combineDateEntities(regexEntities: [PIIEntity], mlEntities: [PIIEntity]) -> [PIIEntity] {
        var combined = regexEntities
        
        for mlEntity in mlEntities {
            let hasOverlap = regexEntities.contains { regexEntity in
                entitiesOverlap(mlEntity, regexEntity)
            }
            
            if !hasOverlap {
                combined.append(mlEntity)
            }
        }
        
        return combined
    }
    
    private func entitiesOverlap(_ entity1: PIIEntity, _ entity2: PIIEntity) -> Bool {
        let range1 = entity1.startIndex..<entity1.endIndex
        let range2 = entity2.startIndex..<entity2.endIndex
        
        return range1.overlaps(range2)
    }
    
    private func removeDuplicatesAndOverlaps(_ entities: [PIIEntity]) -> [PIIEntity] {
        var result: [PIIEntity] = []
        
        let sortedEntities = entities.sorted { $0.startIndex < $1.startIndex }
        
        for entity in sortedEntities {
            let hasOverlap = result.contains { existing in
                entitiesOverlap(entity, existing)
            }
            
            if !hasOverlap {
                result.append(entity)
            } else {
                // If there's overlap, choose the longer/more complete entity
                if let overlappingIndex = result.firstIndex(where: { entitiesOverlap(entity, $0) }) {
                    let existing = result[overlappingIndex]
                    
                    if entity.text.count > existing.text.count {
                        result[overlappingIndex] = entity
                    } else {
                    }
                }
            }
        }
        
        return result
    }
}
