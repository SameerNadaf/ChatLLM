//
//  Logger.swift
//  ChatLLM
//
//  Created by Sameer on 02/12/25.
//

import Foundation
import os

/// A centralized logging utility for the application.
struct AppLogger {

    /// Represents a specific category for logging.
    struct CategoryLogger {
        /// The name of the category (e.g., "LLM", "Chat").
        let name: String
        /// The system logger instance associated with this category.
        let logger: Logger
    }

    private static let subsystem = Bundle.main.bundleIdentifier ?? "com.chatllm.app"
    
    /// Logger for LLM-related activities.
    static let llm = CategoryLogger(
        name: "LLM",
        logger: Logger(subsystem: subsystem, category: "LLMService")
    )

    /// Logger for Chat UI and logic.
    static let chat = CategoryLogger(
        name: "Chat",
        logger: Logger(subsystem: subsystem, category: "ChatView")
    )

    /// Logger for Settings-related activities.
    static let settings = CategoryLogger(
        name: "Settings",
        logger: Logger(subsystem: subsystem, category: "SettingsView")
    )

    /// Logs a message to the console and the system log.
    /// - Parameters:
    ///   - category: The category logger to use.
    ///   - message: The message string to log.
    ///   - type: The OSLogType (default is .default).
    static func log(category: CategoryLogger, message: String, type: OSLogType = .default) {

        let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)

        // Print to console (nice formatting)
        print("\(timestamp) [\(category.name)]: \(message)")
    }
}
