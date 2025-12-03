//
//  ChatLLMApp.swift
//  ChatLLM
//
//  Created by Sameer on 02/12/25.
//

import SwiftUI

@main
struct ChatLLMApp: App {
    // 1. Initialize the service and make it available globally
    @StateObject var llmService = LLMService()
    
    var body: some Scene {
        WindowGroup {
            // 2. Inject the environment object into the starting view
            ChatView()
                .environmentObject(llmService)
        }
    }
}
