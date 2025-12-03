//
//  View.swift
//  ChatLLM
//
//  Created by CIPL User01 on 03/12/25.
//

import SwiftUI

extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
