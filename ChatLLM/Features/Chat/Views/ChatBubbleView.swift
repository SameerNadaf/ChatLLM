//
//  ChatBubbleView.swift
//  ChatLLM
//
//  Created by CIPL User01 on 03/12/25.
//

import SwiftUI

struct ChatBubbleView: View {
    let message: ChatMessage
    var showActions: Bool = true
    var modelName: String = "AI"
    @State private var isCopied = false
    @State private var liked: Bool? = nil   // nil = no vote, true = like, false = dislike
    
    var body: some View {
        VStack(alignment: message.isUser ? .trailing : .leading, spacing: 6) {
            HStack(alignment: .top, spacing: 8) {
                
                // MODEL MESSAGE
                if !message.isUser {
                    // Optional avatar
                    VStack(alignment: .leading) {
                        HStack {
                            Image("chatAI")
                                .renderingMode(.template)
                                .resizable()
                                .scaledToFit()
                                .foregroundStyle(.secondary)
                                .frame(width: 22, height: 22)
                            
                            Text(modelName)
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundStyle(.secondary)
                        }
                        
                        // MARKDOWN MESSAGE
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(parseMarkdown(message.text), id: \.id) { block in
                                switch block.type {
                                case .text(let content):
                                    Text(.init(content)) // Use SwiftUI Markdown for bold/italics
                                        .foregroundColor(.primary)
                                        .font(.body)
                                        .fixedSize(horizontal: false, vertical: true)
                                case .code(let language, let code):
                                    CodeBlockView(language: language, code: code)
                                }
                            }
                        }
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
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            withAnimation {
                                isCopied = false
                            }
                        }
                    } label: {
                        Image(systemName: isCopied ? "checkmark" : "doc.on.doc")
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

#Preview {
    ChatBubbleView(message: ChatMessage(text: "Hello world!", isUser: true, modelName: "llama"))
}
