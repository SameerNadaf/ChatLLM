//
//  LLMModelLoader.swift
//  ChatLLM
//
//  Created by CIPL User01 on 03/12/25.
//

import Foundation
import LLM

final class LLMModelLoader {
    static let shared = LLMModelLoader()
    private init() {}

    func loadModel(at path: URL) async -> LLM? {
        let template = Template.chatML("You are a helpful assistant. Answer concisely and directly.")
        return await Task.detached(priority: .userInitiated) {
            return LLM(from: path, template: template)
        }.value
    }
}

