//
//  Logger.swift
//  ChatLLM
//
//  Created by Sameer on 02/12/25.
//

import Foundation
import os

struct AppLogger {

    struct CategoryLogger {
        let name: String        // "LLM", "Chat", "Settings"
        let logger: Logger      // actual system logger
    }

    private static let subsystem = Bundle.main.bundleIdentifier ?? "com.chatllm.app"

    // Our explicit category mapping
    static let llm = CategoryLogger(
        name: "LLM",
        logger: Logger(subsystem: subsystem, category: "LLMService")
    )

    static let chat = CategoryLogger(
        name: "Chat",
        logger: Logger(subsystem: subsystem, category: "ChatView")
    )

    static let settings = CategoryLogger(
        name: "Settings",
        logger: Logger(subsystem: subsystem, category: "SettingsView")
    )

    static func log(category: CategoryLogger, message: String, type: OSLogType = .default) {

        let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)

        // Print to console (nice formatting)
        print("\(timestamp) [\(category.name)]: \(message)")
    }
}
