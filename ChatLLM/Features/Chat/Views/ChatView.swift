//
//  ChatView.swift
//  ChatLLM
//
//  Created by Sameer on 02/12/25.
//

import SwiftUI

struct ChatView: View {
    @EnvironmentObject var service: LLMService
    
    var body: some View {
        ChatViewContent(vm: ChatViewModel(service: service))
            .environmentObject(service)
    }
}

struct ChatViewContent: View {
    @EnvironmentObject var service: LLMService
    @StateObject var vm: ChatViewModel
    @StateObject private var keyboard = KeyboardObserver()
    @StateObject private var keyboardState = KeyboardState()
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                messagesScrollView
            }
            .navigationTitle("ChatLLM")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink { SettingsView() } label: {
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
    }
}


extension ChatViewContent {

    var messagesScrollView: some View {
        ZStack(alignment: .bottomTrailing) {

            if vm.messages.isEmpty && !vm.isGenerating && !keyboardState.isVisible {
                VStack {
                    LottieAnimationView(fileName: "emptyGhost", title: "Start a conversation!")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding(.bottom, 40)
                }
            }

            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack {
                        ForEach(vm.messages) { message in
                            ChatBubbleView(
                                message: message,
                                showActions: true,
                                modelName: message.modelName ?? "AI"
                            )
                            .id(message.id)
                        }

                        if vm.isGenerating {
                            ChatBubbleView(
                                message: ChatMessage(
                                    text: vm.streamingResponse + "█",
                                    isUser: false
                                ),
                                showActions: false,
                                modelName: service.currentModelName
                            )
                            .id("stream")
                        }

                        Color.clear
                            .frame(height: 1)
                            .id("bottom")
                            .onAppear { vm.isLastMessageVisible = true }
                            .onDisappear { vm.isLastMessageVisible = false }
                    }
                    .padding()
                }
                .onChange(of: vm.messages.count) {
                    withAnimation { proxy.scrollTo("bottom", anchor: .bottom) }
                }
                .onChange(of: vm.streamingResponse) {
                    withAnimation { proxy.scrollTo("bottom", anchor: .bottom) }
                }
                .overlay(alignment: .bottomTrailing) {
                    if !vm.isLastMessageVisible && !vm.messages.isEmpty {
                        Button {
                            withAnimation {
                                proxy.scrollTo("bottom", anchor: .bottom)
                            }
                        } label: {
                            Image(systemName: "arrow.down.circle")
                                .font(.system(size: 32))
                                .foregroundStyle(Color("backgroundColor"))
                                .background(Circle().fill(Color.primary))
                                .shadow(radius: 4)
                        }
                        .padding(20)
                        .transition(.opacity)
                    }
                }
            }
            .onTapGesture { hideKeyboard() }
        }
    }
}

extension ChatViewContent {
    var inputBar: some View {
        HStack {
            TextField("Ask anything", text: $vm.inputText, axis: .vertical)
                .padding(.horizontal)
                .frame(minHeight: 44)
                .background(Color("backgroundColor"))
                .clipShape(Capsule(style: .circular))
            
            if vm.isGenerating {
                Button {
                    vm.stopGeneration()
                } label: {
                    Image(systemName: "stop.circle.fill")
                        .font(.system(size: 32))
                        .foregroundColor(.red)
                }
            } else {
                Button {
                    hideKeyboard()
                    Task { await vm.sendTapped() }
                } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 32))
                }
                .disabled(vm.inputText.isEmpty)
            }
        }
        .padding()
    }
}


#Preview {
    ChatView()
        .environmentObject(LLMService())
}
