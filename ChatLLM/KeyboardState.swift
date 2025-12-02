//
//  KeyboardState.swift
//  ChatLLM
//
//  Created by Sameer on 02/12/25.
//

import Combine
import UIKit

final class KeyboardState: ObservableObject {
    @Published var isVisible = false
    private var cancellables = Set<AnyCancellable>()

    init() {
        NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)
            .sink { _ in self.isVisible = true }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)
            .sink { _ in self.isVisible = false }
            .store(in: &cancellables)
    }
}
