//
//  ChatViewModel.swift
//  ChatLLM
//
//  Created by Sameer on 03/12/25.
//

import SwiftUI

@MainActor
class ChatViewModel: ObservableObject {
    @Published var inputText: String = ""
    @Published var messages: [ChatMessage] = []
    @Published var isGenerating: Bool = false
    @Published var streamingResponse: String = ""
    @Published var isLastMessageVisible: Bool = true
    
    private let service: LLMService
    
    init(service: LLMService) {
        self.service = service
    }
    
    func sendTapped() async {
        let trimmed = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        inputText = ""
        messages.append(ChatMessage(text: trimmed, isUser: true))
        
        isGenerating = true
        streamingResponse = ""
        
        let stream = await service.sendMessageStream(trimmed)
        
        for await token in stream {
            streamingResponse += token
        }
        
        if !streamingResponse.isEmpty {
            messages.append(
                ChatMessage(
                    text: streamingResponse,
                    isUser: false,
                    modelName: service.currentModelName
                )
            )
        }
        
        streamingResponse = ""
        isGenerating = false
    }
    
    func stopGeneration() {
        service.stopGeneration()
        isGenerating = false
    }
}
