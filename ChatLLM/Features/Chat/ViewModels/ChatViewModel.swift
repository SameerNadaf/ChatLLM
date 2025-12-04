//
//  ChatViewModel.swift
//  ChatLLM
//
//  Created by Sameer on 03/12/25.
//

import SwiftUI

/// ViewModel managing the state and logic for the Chat view.
@MainActor
class ChatViewModel: ObservableObject {
    /// The current text input by the user.
    @Published var inputText: String = ""
    /// The list of chat messages in the conversation.
    @Published var messages: [ChatMessage] = []
    /// Indicates whether the AI is currently generating a response.
    @Published var isGenerating: Bool = false
    /// Holds the partial response text while streaming.
    @Published var streamingResponse: String = ""
    /// Indicates if the last message is currently visible in the scroll view.
    @Published var isLastMessageVisible: Bool = true
    
    private let service: LLMService
    
    /// Initializes the ChatViewModel with the shared LLM service.
    /// - Parameter service: The LLMService instance.
    init(service: LLMService) {
        self.service = service
    }
    
    /// Handles the send button tap action.
    /// Validates input, updates UI state, and initiates the message stream from the LLM service.
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
    
    /// Stops the current text generation process.
    func stopGeneration() {
        service.stopGeneration()
        isGenerating = false
    }
}
