//
//  ChatView.swift
//  ChatLLM
//
//  Created by Sameer on 02/12/25.
//

import SwiftUI

struct ChatView: View {
    @EnvironmentObject var service: LLMService
    
    @State private var inputText: String = ""
    @State private var messages: [ChatMessage] = []
    @State private var isGenerating: Bool = false
    @State private var streamingResponse: String = ""
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                messagesScrollView
                inputBar
            }
            .navigationTitle("Local LLM Chat")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        SettingsView()
                    } label: {
                        Image(systemName: "gearshape")
                    }
                }
            }
        }
        .onAppear {
            AppLogger.log(category: AppLogger.chat, message: "ChatView appeared.")
        }
    }
    
    // MARK: - Scrollable messages
    var messagesScrollView: some View {
        ScrollViewReader { proxy in
            List {
                ForEach(messages) { message in
                    ChatBubble(message: message)
                }
                
                if isGenerating {
                    ChatBubble(
                        message: ChatMessage(text: streamingResponse + "█", isUser: false)
                    )
                    .id("stream")
                }
            }
            .listStyle(.plain)
            .onChange(of: messages.count) {
                AppLogger.log(category: AppLogger.chat, message: "Message count updated: \(messages.count)")
                withAnimation {
                    proxy.scrollTo(messages.last?.id, anchor: .bottom)
                }
            }
            .onChange(of: streamingResponse) {
                withAnimation {
                    proxy.scrollTo("stream", anchor: .bottom)
                }
            }
        }
    }
    
    // MARK: - Input bar
    var inputBar: some View {
        HStack {
            TextField("Ask the model...", text: $inputText, axis: .vertical)
                .padding(.leading)
                .frame(height: 44)
                .background(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.leading)
            
            Button {
                Task { await sendTapped() }
            } label: {
                Image(systemName: "paperplane.fill")
                    .font(.system(size: 26))
            }
            .disabled(inputText.isEmpty || isGenerating || !service.isModelReady)
            .padding(.trailing)
        }
        .frame(minHeight: 60)
        .background(.ultraThinMaterial)
    }
    
    // MARK: - Send Action
    
    func sendTapped() async {
        guard !inputText.isEmpty else { return }
        
        let userText = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        AppLogger.log(category: AppLogger.chat, message: "User tapped send. Input length: \(userText.count)")
        inputText = ""
        
        messages.append(ChatMessage(text: userText, isUser: true))
        
        isGenerating = true
        streamingResponse = ""
        
        // 🚀 Use the CORRECT streaming method
        AppLogger.log(category: AppLogger.chat, message: "Initiating stream request...")
        let stream = await service.sendMessageStream(userText)
        
        // Read tokens as they arrive
        for await token in stream {
            streamingResponse += token
        }
        AppLogger.log(category: AppLogger.chat, message: "Stream loop finished. Final response length: \(streamingResponse.count)")
        
        // Commit assistant message
        if !streamingResponse.isEmpty {
            messages.append(ChatMessage(text: streamingResponse, isUser: false))
            AppLogger.log(category: AppLogger.chat, message: "Assistant message appended to chat.")
        } else {
            AppLogger.log(category: AppLogger.chat, message: "Stream response was empty.", type: .fault)
        }
        
        streamingResponse = ""
        isGenerating = false
    }
}

// MARK: - Chat Model + Bubble

struct ChatMessage: Identifiable {
    let id = UUID()
    let text: String
    let isUser: Bool
}

struct ChatBubble: View {
    let message: ChatMessage
    
    var body: some View {
        HStack {
            if message.isUser { Spacer() }
            
            Text(message.text)
                .padding(12)
                .background(message.isUser ? Color.blue : Color(UIColor.systemGray5))
                .foregroundColor(message.isUser ? .white : .primary)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .frame(maxWidth: 300, alignment: message.isUser ? .trailing : .leading)
            
            if !message.isUser { Spacer() }
        }
        .listRowSeparator(.hidden)
    }
}

#Preview {
    ChatView()
        .environmentObject(LLMService())
}
