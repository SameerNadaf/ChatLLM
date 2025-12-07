//
//  ChatMessage.swift
//  ChatLLM
//
//  Created by Sameer on 03/12/25.
//

import Foundation

/// Represents a single message in the chat conversation.
struct ChatMessage: Identifiable {
    let id = UUID()
    let text: String
    let isUser: Bool
    var modelName: String? = nil
}
