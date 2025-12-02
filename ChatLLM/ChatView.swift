//
//  ChatView.swift
//  ChatLLM
//
//  Created by Sameer on 02/12/25.
//

import SwiftUI

struct ChatView: View {
    @EnvironmentObject var service: LLMService
    @StateObject private var keyboard = KeyboardObserver()
    @StateObject private var keyboardState = KeyboardState()

    
    @State private var inputText: String = ""
    @State private var messages: [ChatMessage] = []
    @State private var isGenerating: Bool = false
    @State private var streamingResponse: String = ""
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                messagesScrollView
            }
            .onTapGesture {
                hideKeyboard()
            }
            .navigationTitle("ChatLLM")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        SettingsView()
                    } label: {
                        Image(systemName: "gearshape")
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                inputBar
                    .background(.ultraThinMaterial)
            }
        }
        .onAppear {
            AppLogger.log(category: AppLogger.chat, message: "ChatView appeared.")
        }
    }
    
    // MARK: - Scrollable messages
    var messagesScrollView: some View {
        ZStack {
            // Lottie Placeholder when empty
            if messages.isEmpty && !isGenerating && !keyboardState.isVisible {
                VStack {
                    LottieAnimationView(fileName: "emptyGhost", title: "Start a conversation!", subtitle: "Start fresh conversation with ChatLLM")
                }
            }

            // Actual Messages + Streaming Bubble
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
                .opacity(messages.isEmpty && !isGenerating ? 0 : 1)
                .listStyle(.plain)
                .onChange(of: messages.count) {
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
    }

    
    // MARK: - Input bar
    var inputBar: some View {
        HStack {
            TextField("Ask the model...", text: $inputText, axis: .vertical)
                .padding()
                .frame(minHeight: 44)
                .background(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            
            Button {
                Task { await sendTapped() }
            } label: {
                Image(systemName: "paperplane.fill")
                    .font(.system(size: 26))
            }
            .disabled(inputText.isEmpty || isGenerating || !service.isModelReady)
        }
        .padding()
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
        
        // Use the CORRECT streaming method
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

extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder),
                                        to: nil, from: nil, for: nil)
    }
}


#Preview {
    ChatView()
        .environmentObject(LLMService())
}
