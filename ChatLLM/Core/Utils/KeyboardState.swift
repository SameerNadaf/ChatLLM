//
//  KeyboardState.swift
//  ChatLLM
//
//  Created by Sameer on 02/12/25.
//

import Combine
import UIKit

/// Observes the visibility state of the keyboard.
final class KeyboardState: ObservableObject {
    /// Indicates whether the keyboard is currently visible.
    @Published var isVisible = false
    private var cancellables = Set<AnyCancellable>()

    /// Initializes the observer and starts listening for keyboard show/hide notifications.
    init() {
        NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)
            .sink { _ in self.isVisible = true }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)
            .sink { _ in self.isVisible = false }
            .store(in: &cancellables)
    }
}
