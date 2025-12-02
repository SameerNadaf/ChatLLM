//
//  LLMService.swift
//  ChatLLM
//
//  Created by Sameer on 02/12/25.
//

import Foundation
import SwiftUI
import LLM

// MARK: - Download State
enum DownloadState {
    case notDownloaded
    case downloading(progress: Double)
    case downloaded(path: URL)
    case failed(error: String)
}

// MARK: - Model Struct
struct AvailableModel: Identifiable {
    let id = UUID()
    let name: String
    let filename: String
    let downloadUrl: URL

    var downloadState: DownloadState = .notDownloaded
    var isSelected: Bool = false
}

// MARK: - LLM Service
@MainActor
final class LLMService: ObservableObject {

    // Published for UI
    @Published var availableModels: [AvailableModel]
    @Published var isModelLoading = false
    @Published var isModelReady = false

    private var llm: LLM?
    private let fm = FileManager.default
    private let selectedModelKey = "SelectedModelFilename"

    // Chat history for ChatML formatting
    private var history: [(role: String, content: String)] = []

    // MARK: - Init
    init() {

        self.availableModels = [
            // QWEN 2.5 (1.5B) — BEST small model
            AvailableModel(
                name: "Qwen2.5 1.5B Instruct",
                filename: "qwen2.5-1.5b-instruct-q4_k_m.gguf",
                downloadUrl: URL(string:
                    "https://huggingface.co/Qwen/Qwen2.5-1.5B-Instruct-GGUF/resolve/main/qwen2.5-1.5b-instruct-q4_k_m.gguf?download=1"
                )!
            ),

            // TINYLLAMA 1.1B — FASTEST
            AvailableModel(
                name: "TinyLlama 1.1B Chat",
                filename: "tinyllama-1.1b-chat-v1.0.Q4_K_M.gguf",
                downloadUrl: URL(string:
                    "https://huggingface.co/TheBloke/TinyLlama-1.1B-Chat-v1.0-GGUF/resolve/main/tinyllama-1.1b-chat-v1.0.Q4_K_M.gguf?download=1"
                )!
            ),

            // MISTRAL 7B — HEAVY (iPhone might struggle)
            AvailableModel(
                name: "Mistral 7B Instruct",
                filename: "mistral-7b-instruct-v0.2.Q4_K_M.gguf",
                downloadUrl: URL(string:
                    "https://huggingface.co/TheBloke/Mistral-7B-Instruct-v0.2-GGUF/resolve/main/mistral-7b-instruct-v0.2.Q4_K_M.gguf?download=1"
                )!
            )
        ]

        createDirectory()
        loadInitialModelStates()

        if let filename = UserDefaults.standard.string(forKey: selectedModelKey) {
            Task { await loadModel(filename: filename) }
        }
    }

    // MARK: - FS Helpers
    private var modelsDir: URL {
        fm.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("LLM_Models")
    }

    private func createDirectory() {
        if !fm.fileExists(atPath: modelsDir.path) {
            try? fm.createDirectory(at: modelsDir, withIntermediateDirectories: true)
        }
    }

    private func localModelURL(_ filename: String) -> URL {
        modelsDir.appendingPathComponent(filename)
    }

    private func loadInitialModelStates() {
        for i in availableModels.indices {
            let path = localModelURL(availableModels[i].filename)
            if fm.fileExists(atPath: path.path) {
                availableModels[i].downloadState = .downloaded(path: path)
            }
        }
    }

    // MARK: - Download
    func downloadModel(_ model: AvailableModel) {
        guard let idx = availableModels.firstIndex(where: { $0.id == model.id }) else { return }

        let dest = localModelURL(model.filename)
        availableModels[idx].downloadState = .downloading(progress: 0)

        // HuggingFace requires a browser-like User-Agent
        var request = URLRequest(url: model.downloadUrl)
        request.setValue("Mozilla/5.0", forHTTPHeaderField: "User-Agent")

        let delegate = DownloadDelegate(
            onProgress: { [weak self] progress in
                Task { @MainActor in
                    self?.availableModels[idx].downloadState = .downloading(progress: progress)
                }
            },
            onComplete: { [weak self] temp in
                Task { @MainActor in
                    guard let self = self else { return }
                    do {
                        if self.fm.fileExists(atPath: dest.path) {
                            try self.fm.removeItem(at: dest)
                        }
                        try self.fm.moveItem(at: temp, to: dest)
                        self.availableModels[idx].downloadState = .downloaded(path: dest)
                    } catch {
                        self.availableModels[idx].downloadState = .failed(error: error.localizedDescription)
                    }
                }
            },
            onError: { [weak self] error in
                Task { @MainActor in
                    self?.availableModels[idx].downloadState = .failed(error: error.localizedDescription)
                }
            }
        )

        let session = URLSession(
            configuration: .default,
            delegate: delegate,
            delegateQueue: nil
        )

        let task = session.downloadTask(with: request)
        task.resume()
    }

    // MARK: - Model Loading
    func loadModel(filename: String) async {
        isModelLoading = true
        isModelReady = false
        llm = nil

        let path = localModelURL(filename)
        guard fm.fileExists(atPath: path.path) else {
            isModelLoading = false
            return
        }

        do {
            let template = Template.chatML("You are a helpful assistant.")
            guard let loaded = LLM(from: path, template: template) else {
                print("Failed to init LLM: returned nil")
                isModelLoading = false
                return
            }

            llm = loaded
            isModelReady = true
            history.removeAll()

            for i in availableModels.indices { availableModels[i].isSelected = false }
            if let idx = availableModels.firstIndex(where: { $0.filename == filename }) {
                availableModels[idx].isSelected = true
            }

            UserDefaults.standard.set(filename, forKey: selectedModelKey)

        } catch {
            print("LLM init error:", error)
        }

        isModelLoading = false
    }

    // MARK: - Prompt builder (ChatML)
    private func buildPrompt(_ user: String) -> String {
        var s = ""
        for msg in history {
            s += "<|\(msg.role)|>\n\(msg.content)\n"
        }
        s += "<|user|>\n\(user)\n<|assistant|>\n"
        return s
    }

    // MARK: - STREAMING MESSAGE
    func sendMessageStream(_ text: String) async -> AsyncStream<String> {
        guard let llm else {
            return AsyncStream { c in c.yield("Model not loaded."); c.finish() }
        }

        let prompt = buildPrompt(text)
        history.append(("user", text))

        return AsyncStream { continuation in
            let originalUpdate = llm.update
            llm.update = { delta in
                Task { @MainActor in
                    if let d = delta {
                        continuation.yield(d)
                    } else {
                        continuation.finish()
                    }
                }
            }

            Task {
                await llm.respond(to: prompt)

                // Save final assistant message
                let final = llm.output.trimmingCharacters(in: .whitespacesAndNewlines)
                history.append(("assistant", final))

                llm.update = originalUpdate
            }

            continuation.onTermination = { _ in
                Task { @MainActor in
                    llm.stop()
                    llm.update = originalUpdate
                }
            }
        }
    }

    // MARK: - NON-STREAMING (Final output only)
    func sendMessage(_ text: String) async -> String {
        guard let llm else { return "Model not loaded." }

        let prompt = buildPrompt(text)
        history.append(("user", text))

        await llm.respond(to: prompt)

        let output = llm.output.trimmingCharacters(in: .whitespacesAndNewlines)
        history.append(("assistant", output))

        return output
    }
}

// MARK: - Download Delegate
private final class DownloadDelegate: NSObject, URLSessionDownloadDelegate {
    let onProgress: (Double) -> Void
    let onComplete: (URL) -> Void
    let onError: (Error) -> Void

    init(
        onProgress: @escaping (Double) -> Void,
        onComplete: @escaping (URL) -> Void,
        onError: @escaping (Error) -> Void
    ) {
        self.onProgress = onProgress
        self.onComplete = onComplete
        self.onError = onError
    }

    func urlSession(_ session: URLSession,
                    downloadTask: URLSessionDownloadTask,
                    didWriteData bytesWritten: Int64,
                    totalBytesWritten: Int64,
                    totalBytesExpectedToWrite: Int64) {

        guard totalBytesExpectedToWrite > 0 else { return }
        onProgress(Double(totalBytesWritten) / Double(totalBytesExpectedToWrite))
    }

    func urlSession(_ session: URLSession,
                    downloadTask: URLSessionDownloadTask,
                    didFinishDownloadingTo location: URL) {
        onComplete(location)
    }

    func urlSession(_ session: URLSession,
                    task: URLSessionTask,
                    didCompleteWithError error: Error?) {
        if let error { onError(error) }
    }
}
