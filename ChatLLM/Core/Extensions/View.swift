//
//  View.swift
//  ChatLLM
//
//  Created by CIPL User01 on 03/12/25.
//

import SwiftUI

extension View {
    /// Dismisses the keyboard by resigning the first responder status.
    /// This is useful for hiding the keyboard when the user taps outside of a text field.
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
