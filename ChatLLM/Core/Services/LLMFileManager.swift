//
//  LLMFileManager.swift
//  ChatLLM
//
//  Created by CIPL User01 on 03/12/25.
//

import Foundation

final class LLMFileManager {
    static let shared = LLMFileManager()
    private init() {}

    private let fm = FileManager.default

    var modelsDir: URL {
        fm.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("LLM_Models")
    }

    func createDirectory() {
        if !fm.fileExists(atPath: modelsDir.path) {
            try? fm.createDirectory(at: modelsDir, withIntermediateDirectories: true)
        }
    }

    func localModelURL(_ filename: String) -> URL {
        modelsDir.appendingPathComponent(filename)
    }

    func modelExists(_ filename: String) -> Bool {
        fm.fileExists(atPath: localModelURL(filename).path)
    }

    func deleteModel(_ filename: String) throws {
        let path = localModelURL(filename)
        if fm.fileExists(atPath: path.path) {
            try fm.removeItem(at: path)
        }
    }

    func moveDownloadedTempFile(temp: URL, dest: URL) throws {
        if fm.fileExists(atPath: dest.path) {
            try fm.removeItem(at: dest)
        }
        try fm.moveItem(at: temp, to: dest)
    }
}
