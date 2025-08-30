//
//  TextProcessor.swift
//  RedactKit
//
//  Created by Supachod Trakansirorut on 30/8/25.
//

import SwiftUI
import CoreML

class TextProcessor: ObservableObject {
    @Published var originalText: AttributedString = ""
    @Published var injectedText: AttributedString = ""
    
    enum TextTarget {
        case original
        case injected
    }
    
    struct TextOccurrence {
        let position: Int
        let target: String
        let replacement: String
    }
    
    @Published var currentReplacements: [(String, String)] = []

    
    // Helper function to swap key-value pairs in the dictionary
    private func swapReplacements(_ replacements: [(String, String)]) -> [(String, String)] {
        return replacements.map { ($0.1, $0.0) }
    }
    
    // Updated public functions with text target parameter
    func changeAttributedText(on target: TextTarget = .original, completion: @escaping () -> Void) {
        let occurrences = findAllOccurrences(replacements: currentReplacements, in: target)
        executeReplacementsInOrder(occurrences: occurrences, on: target, completion: completion)
    }
    
    func revertAttributedText(on target: TextTarget = .injected, completion: @escaping () -> Void) {
        let reversedReplacements = swapReplacements(currentReplacements)
        let occurrences = findAllOccurrences(replacements: reversedReplacements, in: target)
        executeReplacementsInOrder(occurrences: occurrences, on: target, completion: completion)
    }
    
    // Helper to get the correct text binding
    private func getTextBinding(for target: TextTarget) -> Binding<AttributedString> {
        switch target {
        case .original:
            return Binding(
                get: { self.originalText },
                set: { self.originalText = $0 }
            )
        case .injected:
            return Binding(
                get: { self.injectedText },
                set: { self.injectedText = $0 }
            )
        }
    }
    
    // Helper to get the text value
    private func getText(for target: TextTarget) -> AttributedString {
        switch target {
        case .original:
            return originalText
        case .injected:
            return injectedText
        }
    }
    
    // Helper to set the text value
    private func setText(_ text: AttributedString, for target: TextTarget) {
        switch target {
        case .original:
            originalText = text
        case .injected:
            injectedText = text
        }
    }
    
    private func executeReplacementsInOrder(occurrences: [TextOccurrence], on target: TextTarget, completion: @escaping () -> Void) {
        // Step 1: Color all target words immediately
        colorAllTargetWords(occurrences: occurrences, on: target)
        
        let group = DispatchGroup()
        
        // Step 2: Replace one by one with delay
        for (index, occurrence) in occurrences.enumerated() {
            group.enter() // Enter the group for each task
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0 + Double(index) * 1.0) {
                withAnimation(.easeInOut(duration: 0.3)) {
                    var currentText = self.getText(for: target)
                    if let range = currentText.range(of: occurrence.target) {
                        var newText = AttributedString(occurrence.replacement)
                        newText.backgroundColor = .teal
                        newText.foregroundColor = .white
                        currentText.replaceSubrange(range, with: newText)
                        self.setText(currentText, for: target)
                    }
                }
                group.leave() // Leave the group when task completes
            }
        }
        
        // Call completion when ALL tasks are done
        group.notify(queue: .main) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                completion()
            }
        }
    }
    
    private func colorAllTargetWords(occurrences: [TextOccurrence], on target: TextTarget) {
        withAnimation(.easeInOut(duration: 0.5)) {
            var currentText = getText(for: target)
            
            for occurrence in occurrences {
                let text = String(currentText.characters)
                var searchStartIndex = text.startIndex
                
                while searchStartIndex < text.endIndex,
                      let stringRange = text.range(of: occurrence.target,
                                                   range: searchStartIndex..<text.endIndex) {
                    // Convert String range to AttributedString range
                    if let attributedRange = Range(stringRange, in: currentText) {
                        currentText[attributedRange].backgroundColor = .teal
                        currentText[attributedRange].foregroundColor = .white
                    }
                    
                    // Move past this occurrence
                    searchStartIndex = stringRange.upperBound
                }
            }
            
            setText(currentText, for: target)
        }
    }
    
    private func findAllOccurrences(replacements: [(String, String)], in target: TextTarget) -> [TextOccurrence] {
        var occurrences: [TextOccurrence] = []
        let currentText = getText(for: target)
        let plainText = String(currentText.characters)
        
        for (targetString, replacement) in replacements {
            var searchStartIndex = plainText.startIndex
            
            while searchStartIndex < plainText.endIndex,
                  let range = plainText.range(of: targetString, range: searchStartIndex..<plainText.endIndex) {
                let position = plainText.distance(from: plainText.startIndex, to: range.lowerBound)
                occurrences.append(TextOccurrence(position: position, target: targetString, replacement: replacement))
                searchStartIndex = range.upperBound
            }
        }
        
        return occurrences.sorted { $0.position < $1.position }
    }
    
    // Function to update the replacements dictionary dynamically
    func updateReplacements(_ newReplacements: [(String, String)]) {
        currentReplacements = newReplacements
    }
}
