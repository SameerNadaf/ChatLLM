//
//  LLMFileManager.swift
//  ChatLLM
//
//  Created by Sameer on 03/12/25.
//

import Foundation

/// Manages file system operations for LLM models.
final class LLMFileManager {
    /// Shared singleton instance.
    static let shared = LLMFileManager()
    private init() {}

    private let fm = FileManager.default

    /// The directory where models are stored.
    var modelsDir: URL {
        fm.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("LLM_Models")
    }

    /// Creates the models directory if it doesn't exist.
    func createDirectory() {
        if !fm.fileExists(atPath: modelsDir.path) {
            try? fm.createDirectory(at: modelsDir, withIntermediateDirectories: true)
        }
    }

    /// Returns the local URL for a given model filename.
    /// - Parameter filename: The filename of the model.
    /// - Returns: The full local URL.
    func localModelURL(_ filename: String) -> URL {
        modelsDir.appendingPathComponent(filename)
    }

    /// Checks if a model file exists locally.
    /// - Parameter filename: The filename to check.
    /// - Returns: True if the file exists, false otherwise.
    func modelExists(_ filename: String) -> Bool {
        fm.fileExists(atPath: localModelURL(filename).path)
    }

    /// Deletes a model file from local storage.
    /// - Parameter filename: The filename of the model to delete.
    /// - Throws: An error if the file could not be removed.
    func deleteModel(_ filename: String) throws {
        let path = localModelURL(filename)
        if fm.fileExists(atPath: path.path) {
            try fm.removeItem(at: path)
        }
    }

    /// Moves a downloaded temporary file to the final destination.
    /// - Parameters:
    ///   - temp: The temporary file URL.
    ///   - dest: The destination file URL.
    /// - Throws: An error if the move operation fails.
    func moveDownloadedTempFile(temp: URL, dest: URL) throws {
        if fm.fileExists(atPath: dest.path) {
            try fm.removeItem(at: dest)
        }
        try fm.moveItem(at: temp, to: dest)
    }
}
