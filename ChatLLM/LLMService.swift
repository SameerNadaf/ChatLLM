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
    let description: String
    let size: String
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



    // MARK: - Init
    init() {

        self.availableModels = [
            // TINYLLAMA 1.1B — FASTEST
            AvailableModel(
                name: "TinyLlama 1.1B Chat",
                filename: "tinyllama-1.1b-chat-v1.0.Q4_K_M.gguf",
                description: "Fastest, simple chats.",
                size: "637 MB",
                downloadUrl: URL(string:
                    "https://huggingface.co/TheBloke/TinyLlama-1.1B-Chat-v1.0-GGUF/resolve/main/tinyllama-1.1b-chat-v1.0.Q4_K_M.gguf"
                )!
            ),
            
            // DEEPSEEK CODER 1.3B INSTRUCT — High-Performance Coding, Ultra-Low RAM
            AvailableModel(
                name: "Deepseek-Coder 1.3B",
                filename: "deepseek-coder-1.3b-instruct.Q4_K_M.gguf",
                description: "Highly optimized.",
                size: "833 MB",
                downloadUrl: URL(string:
                    "https://huggingface.co/TheBloke/deepseek-coder-1.3b-instruct-GGUF/resolve/main/deepseek-coder-1.3b-instruct.Q4_K_M.gguf"
                )!
            ),
            
            // QWEN 2 (1.5B) — BEST small model
            AvailableModel(
                name: "Qwen2 1.5B Instruct",
                filename: "qwen2-1_5b-instruct-q4_k_m.gguf",
                description: "Best small model, balanced.",
                size: "800 MB",
                downloadUrl: URL(string:
                    "https://huggingface.co/Qwen/Qwen2-1.5B-Instruct-GGUF/resolve/main/qwen2-1_5b-instruct-q4_k_m.gguf"
                )!
            ),
            
            // GEMMA 2B — Safest/Fastest for Math/General Reasoning with Extremely Low RAM
            AvailableModel(
                name: "Gemma 2B Instruct",
                filename: "gemma-2-2b-it-Q4_K_M.gguf",
                description: "Best speed & reasoning.",
                size: "1.6 GB",
                downloadUrl: URL(string:
                    "https://huggingface.co/bartowski/gemma-2-2b-it-GGUF/resolve/main/gemma-2-2b-it-Q4_K_M.gguf"
                )!
            ),
            
            // QWEN 2.5 CODER 3B — Best for Coding/Math with Low RAM
            AvailableModel(
                name: "Qwen2.5-Coder 3B",
                filename: "Qwen2.5-Coder-3B-Q3_K_M.gguf",
                description: "Best coding and math.",
                size: "1.59 GB",
                downloadUrl: URL(string:
                    "https://huggingface.co/bartowski/Qwen2.5-Coder-3B-GGUF/resolve/main/Qwen2.5-Coder-3B-Q3_K_M.gguf"
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

    func deleteModel(_ model: AvailableModel) {
        guard let idx = availableModels.firstIndex(where: { $0.id == model.id }) else { return }
        let path = localModelURL(model.filename)
        
        do {
            if fm.fileExists(atPath: path.path) {
                try fm.removeItem(at: path)
            }
            availableModels[idx].downloadState = .notDownloaded
            availableModels[idx].isSelected = false
            
            // If the deleted model was the active one, clear the active state
            if let current = UserDefaults.standard.string(forKey: selectedModelKey), current == model.filename {
                UserDefaults.standard.removeObject(forKey: selectedModelKey)
                llm = nil
                isModelReady = false
            }
            
        } catch {
            print("Error deleting model: \(error)")
        }
    }

    // MARK: - Model Loading
    func loadModel(filename: String) async {
        // 1. Update UI state on MainActor
        isModelLoading = true
        isModelReady = false
        llm = nil

        let path = localModelURL(filename)
        guard fm.fileExists(atPath: path.path) else {
            isModelLoading = false
            return
        }

        // 2. Offload heavy initialization to a background thread
        //    Using Task.detached keeps it off the MainActor.
        let loadedLLM: LLM? = await Task.detached(priority: .userInitiated) {
            let template = Template.chatML("You are a helpful assistant. Answer concisely and directly.")
            // This is the blocking call:
            return LLM(from: path, template: template)
        }.value

        // 3. Back on MainActor, update state
        guard let validLLM = loadedLLM else {
            print("Failed to init LLM: returned nil")
            isModelLoading = false
            return
        }

        self.llm = validLLM
        self.isModelReady = true

        // Update selection state
        for i in availableModels.indices { availableModels[i].isSelected = false }
        if let idx = availableModels.firstIndex(where: { $0.filename == filename }) {
            availableModels[idx].isSelected = true
        }

        UserDefaults.standard.set(filename, forKey: selectedModelKey)
        isModelLoading = false
    }

    // MARK: - Prompt builder (ChatML)
    private func buildPrompt(_ user: String) -> String {
        return "<|user|>\n\(user)\n<|assistant|>\n"
    }

    // MARK: - STREAMING MESSAGE
    func sendMessageStream(_ text: String) async -> AsyncStream<String> {
        // STATELESS MODE: Re-init model for every request to ensure fresh context.
        guard let filename = UserDefaults.standard.string(forKey: selectedModelKey) else {
             return AsyncStream { c in c.yield("No model selected."); c.finish() }
        }
        
        let path = localModelURL(filename)
        let template = Template.chatML("You are a helpful assistant. Answer concisely and directly.")
        
        // Re-load LLM to clear context
        guard let newLLM = LLM(from: path, template: template) else {
             return AsyncStream { c in c.yield("Failed to load model."); c.finish() }
        }
        self.llm = newLLM
        self.shouldStop = false

        let prompt = buildPrompt(text)

        return AsyncStream { continuation in
            let originalUpdate = newLLM.update
            
            newLLM.update = { delta in
                Task { @MainActor in
                    if self.shouldStop {
                        continuation.finish()
                        return
                    }
                    
                    if let d = delta {
                        continuation.yield(d)
                    } else {
                        continuation.finish()
                    }
                }
            }

            Task {
                await newLLM.respond(to: prompt)
                newLLM.update = originalUpdate
                continuation.finish()
            }

            continuation.onTermination = { _ in
                Task { @MainActor in
                    newLLM.stop()
                    newLLM.update = originalUpdate
                }
            }
        }
    }

    // MARK: - NON-STREAMING (Final output only)
    func sendMessage(_ text: String) async -> String {
        // STATELESS MODE: Re-init model for every request to ensure fresh context.
        guard let filename = UserDefaults.standard.string(forKey: selectedModelKey) else { return "No model selected." }
        
        let path = localModelURL(filename)
        let template = Template.chatML("You are a helpful assistant. Answer concisely and directly. Do not hallucinate.")
        
        guard let newLLM = LLM(from: path, template: template) else { return "Failed to load model." }
        self.llm = newLLM

        let prompt = buildPrompt(text)
        await newLLM.respond(to: prompt)

        return newLLM.output.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    // MARK: - STOP GENERATION
    private var shouldStop = false
    
    func stopGeneration() {
        Task { @MainActor in
            shouldStop = true
            llm?.stop()
        }
    }
    
    var currentModelName: String {
        availableModels.first(where: { $0.isSelected })?.name ?? "AI"
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
        // The file at `location` is deleted as soon as this method returns.
        // We must move it to a safe temporary location synchronously.
        let safeTempURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        do {
            if FileManager.default.fileExists(atPath: safeTempURL.path) {
                try FileManager.default.removeItem(at: safeTempURL)
            }
            try FileManager.default.moveItem(at: location, to: safeTempURL)
            onComplete(safeTempURL)
        } catch {
            onError(error)
        }
    }

    func urlSession(_ session: URLSession,
                    task: URLSessionTask,
                    didCompleteWithError error: Error?) {
        if let error { onError(error) }
    }
}
