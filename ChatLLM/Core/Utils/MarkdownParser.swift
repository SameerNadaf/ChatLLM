//
//  MarkdownParser.swift
//  ChatLLM
//
//  Created by CIPL User01 on 03/12/25.
//

import Foundation

/// Defines the type of a markdown block.
enum MarkdownBlockType {
    case text(String)
    case code(String, String) // language, code
}

/// Represents a parsed block of markdown content.
struct MarkdownBlock: Identifiable {
    let id = UUID()
    let type: MarkdownBlockType
}

/// Parses a raw markdown string into a list of structured blocks.
/// - Parameter text: The raw markdown text to parse.
/// - Returns: An array of `MarkdownBlock` objects representing the parsed content.
func parseMarkdown(_ text: String) -> [MarkdownBlock] {
    var blocks: [MarkdownBlock] = []
    let components = text.components(separatedBy: "```")
    
    for (index, component) in components.enumerated() {
        if index % 2 == 0 {
            let trimmed = component.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty {
                blocks.append(MarkdownBlock(type: .text(trimmed)))
            }
        } else {
            // Odd indices are code blocks
            // Try to extract language from the first line
            let lines = component.split(separator: "\n", maxSplits: 1, omittingEmptySubsequences: false)
            
            var language = "Code"
            var codeContent = component
            
            if let firstLine = lines.first {
                let potentialLang = firstLine.trimmingCharacters(in: .whitespacesAndNewlines)
                if !potentialLang.isEmpty {
                    language = potentialLang
                    // If we found a language, the code is the rest
                    if lines.count > 1 {
                        codeContent = String(lines[1])
                    } else {
                        codeContent = ""
                    }
                }
            }
            
            let trimmedCode = codeContent.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmedCode.isEmpty {
                blocks.append(MarkdownBlock(type: .code(language, trimmedCode)))
            }
        }
    }
    
    // Fallback if empty (shouldn't happen often)
    if blocks.isEmpty && !text.isEmpty {
        blocks.append(MarkdownBlock(type: .text(text)))
    }
    
    return blocks
}
