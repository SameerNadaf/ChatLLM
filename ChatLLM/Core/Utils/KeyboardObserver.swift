//
//  KeyboardObserver.swift
//  ChatLLM
//
//  Created by Sameer on 02/12/25.
//

import SwiftUI
import Combine

/// Observes keyboard height changes and publishes updates.
final class KeyboardObserver: ObservableObject {
    /// The current height of the keyboard.
    @Published var height: CGFloat = 0
    
    private var cancellables = Set<AnyCancellable>()
    
    /// Initializes the observer and starts listening for keyboard notifications.
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
