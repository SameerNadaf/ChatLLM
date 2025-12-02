//
//  KeyboardObserver.swift
//  ChatLLM
//
//  Created by Sameer on 02/12/25.
//

import SwiftUI
import Combine

final class KeyboardObserver: ObservableObject {
    @Published var height: CGFloat = 0
    
    private var cancellables = Set<AnyCancellable>()

    init() {
        let willShow = NotificationCenter.default.publisher(
            for: UIResponder.keyboardWillShowNotification
        )
        let willHide = NotificationCenter.default.publisher(
            for: UIResponder.keyboardWillHideNotification
        )
        
        willShow
            .merge(with: willHide)
            .sink { notification in
                withAnimation(.easeOut(duration: 0.25)) {
                    if notification.name == UIResponder.keyboardWillShowNotification,
                       let frame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
                        self.height = frame.height
                    } else {
                        self.height = 0
                    }
                }
            }
            .store(in: &cancellables)
    }
}
