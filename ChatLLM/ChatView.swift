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
    @State private var isLastMessageVisible: Bool = true
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                messagesScrollView
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
                    .transaction { $0.animation = nil }
            }
        }
        .onAppear {
            AppLogger.log(category: AppLogger.chat, message: "ChatView appeared.")
        }
    }
    
    // MARK: - Scrollable messages
    // MARK: - Scrollable messages
    var messagesScrollView: some View {
        ZStack(alignment: .bottomTrailing) {
            // Lottie Placeholder when empty
            if messages.isEmpty && !isGenerating && !keyboardState.isVisible {
                VStack {
                    LottieAnimationView(fileName: "emptyGhost", title: "Start a conversation!")
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }

            // Actual Messages + Streaming Bubble
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack {
                        ForEach(messages) { message in
                            ChatBubble(message: message, showActions: true)
                                .id(message.id)
                        }

                        if isGenerating {
                            ChatBubble(
                                message: ChatMessage(text: streamingResponse + "█", isUser: false),
                                showActions: false
                            )
                            .id("stream")
                        }
                        
                        // Invisible footer to track bottom visibility
                        Color.clear
                            .frame(height: 1)
                            .id("bottom")
                            .onAppear {
                                isLastMessageVisible = true
                            }
                            .onDisappear {
                                isLastMessageVisible = false
                            }
                    }
                    .padding()
                }
                .onChange(of: messages.count) {
                    withAnimation {
                        proxy.scrollTo("bottom", anchor: .bottom)
                    }
                }
                .onChange(of: streamingResponse) {
                    withAnimation {
                        proxy.scrollTo("bottom", anchor: .bottom)
                    }
                }
                
                // Floating Scroll Button (Overlay)
                .overlay(alignment: .bottomTrailing) {
                    if !isLastMessageVisible && !messages.isEmpty {
                        Button {
                            withAnimation {
                                proxy.scrollTo("bottom", anchor: .bottom)
                            }
                        } label: {
                            Image(systemName: "arrow.down.circle.fill")
                                .font(.system(size: 32))
                                .background(Circle().fill(Color.accentColor))
                                .shadow(radius: 4)
                        }
                        .padding(20)
                        .transition(.opacity)
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
                .background(Color("backgroundColor"))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            
            if isGenerating {
                Button {
                    service.stopGeneration()
                } label: {
                    Image(systemName: "stop.circle.fill")
                        .font(.system(size: 30))
                        .foregroundColor(.red)
                }
            } else {
                Button {
                    hideKeyboard()
                    Task { await sendTapped() }
                } label: {
                    Image(systemName: "paperplane.fill")
                        .font(.system(size: 26))
                }
                .disabled(inputText.isEmpty)
            }
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
    var showActions: Bool = true
    @State private var isCopied = false
    @State private var liked: Bool? = nil   // nil = no vote, true = like, false = dislike
    
    var body: some View {
        VStack(alignment: message.isUser ? .trailing : .leading, spacing: 6) {
            HStack(alignment: .top, spacing: 8) {
                
                // MODEL MESSAGE
                if !message.isUser {
                    // Optional avatar
                    VStack(alignment: .leading) {
                        Image("chatAI")
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .foregroundStyle(.primary)
                            .frame(width: 30, height: 30)
                        
                        Text(message.text)
                            .foregroundColor(.primary)
                            .font(.body)
                            .padding(.vertical, 6)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                
                // USER MESSAGE
                if message.isUser {
                    Spacer()
                    
                    Text(message.text)
                        .padding(12)
                        .font(.body)
                        .background(Color.secondary.opacity(0.3))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .frame(maxWidth: 260, alignment: .trailing)
                }
            }
            
            // MARK: - ACTION BUTTONS (only for model messages)
            if !message.isUser && showActions {
                HStack(spacing: 14) {
                    
                    // Copy Button
                    Button {
                        UIPasteboard.general.string = message.text
                        withAnimation {
                            isCopied = true
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                            withAnimation {
                                isCopied = false
                            }
                        }
                    } label: {
                        Label(isCopied ? "Copied" : "Copy",
                              systemImage: isCopied ? "checkmark" : "doc.on.doc")
                            .font(.caption)
                    }
                    .buttonStyle(.borderless)
                    
                    // Like Button
                    Button {
                        liked = liked == true ? nil : true
                    } label: {
                        Image(systemName: liked == true ? "hand.thumbsup.fill" : "hand.thumbsup")
                            .font(.caption)
                    }
                    .buttonStyle(.borderless)
                    
                    // Dislike Button
                    Button {
                        liked = liked == false ? nil : false
                    } label: {
                        Image(systemName: liked == false ? "hand.thumbsdown.fill" : "hand.thumbsdown")
                            .font(.caption)
                    }
                    .buttonStyle(.borderless)
                    
                    Spacer()
                }
                .padding(.top, 2)
                .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 6)
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
