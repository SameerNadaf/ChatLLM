//
//  LLMModelLoader.swift
//  ChatLLM
//
//  Created by CIPL User01 on 03/12/25.
//

import Foundation
import LLM

/// Handles loading of LLM models into memory.
final class LLMModelLoader {
    /// Shared singleton instance.
    static let shared = LLMModelLoader()
    private init() {}

    /// Loads an LLM model from the specified file path.
    /// - Parameter path: The local URL of the model file.
    /// - Returns: An initialized `LLM` instance, or nil if loading fails.
    func loadModel(at path: URL) async -> LLM? {
        let template = Template.chatML("You are a helpful assistant. Answer concisely and directly.")
        return await Task.detached(priority: .userInitiated) {
            return LLM(from: path, template: template)
        }.value
    }
}

