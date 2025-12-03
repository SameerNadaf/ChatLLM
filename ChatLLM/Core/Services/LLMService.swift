//
//  LLMService.swift
//  ChatLLM
//
//  Created by Sameer on 02/12/25.
//

import Foundation
import SwiftUI
import LLM

@MainActor
final class LLMService: ObservableObject {

    // Published (UI Reactive)
    @Published var availableModels: [AvailableModel]
    @Published var isModelLoading = false
    @Published var isModelReady = false

    // Internal State
    private var llm: LLM?
    private var shouldStop = false

    // Dependencies
    private let fm = LLMFileManager.shared
    private let downloader = LLMDownloader()
    private let loader = LLMModelLoader.shared

    private let selectedModelKey = "SelectedModelFilename"

    // Init
    init() {
        self.availableModels = LLMService.defaultModels

        fm.createDirectory()
        loadInitialModelStates()

        if let filename = UserDefaults.standard.string(forKey: selectedModelKey) {
            Task { await loadModel(filename: filename) }
        }
    }
}


// MARK: - Default Model List
extension LLMService {

    static var defaultModels: [AvailableModel] {
        [
            AvailableModel(
                name: "TinyLlama 1.1B Chat",
                filename: "tinyllama-1.1b-chat-v1.0.Q4_K_M.gguf",
                description: "Fastest, simple chats.",
                size: "637 MB",
                downloadUrl: URL(string:
                    "https://huggingface.co/TheBloke/TinyLlama-1.1B-Chat-v1.0-GGUF/resolve/main/tinyllama-1.1b-chat-v1.0.Q4_K_M.gguf"
                )!
            ),
            AvailableModel(
                name: "Deepseek-Coder 1.3B",
                filename: "deepseek-coder-1.3b-instruct.Q4_K_M.gguf",
                description: "Highly optimized.",
                size: "833 MB",
                downloadUrl: URL(string:
                    "https://huggingface.co/TheBloke/deepseek-coder-1.3b-instruct-GGUF/resolve/main/deepseek-coder-1.3b-instruct.Q4_K_M.gguf"
                )!
            ),
            AvailableModel(
                name: "Qwen2 1.5B Instruct",
                filename: "qwen2-1_5b-instruct-q4_k_m.gguf",
                description: "Best small model, balanced.",
                size: "800 MB",
                downloadUrl: URL(string:
                    "https://huggingface.co/Qwen/Qwen2-1.5B-Instruct-GGUF/resolve/main/qwen2-1_5b-instruct-q4_k_m.gguf"
                )!
            ),
            AvailableModel(
                name: "Gemma 2B Instruct",
                filename: "gemma-2-2b-it-Q4_K_M.gguf",
                description: "Best speed & reasoning.",
                size: "1.6 GB",
                downloadUrl: URL(string:
                    "https://huggingface.co/bartowski/gemma-2-2b-it-GGUF/resolve/main/gemma-2-2b-it-Q4_K_M.gguf"
                )!
            ),
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
    }
}

// MARK: - Initial Local State Loading
extension LLMService {

    private func loadInitialModelStates() {
        for i in availableModels.indices {
            let path = fm.localModelURL(availableModels[i].filename)
            if FileManager.default.fileExists(atPath: path.path) {
                availableModels[i].downloadState = .downloaded(path: path)
            }
        }
    }
}

// MARK: - Download
extension LLMService {

    func downloadModel(_ model: AvailableModel) {
        guard let idx = availableModels.firstIndex(where: { $0.id == model.id }) else { return }

        let dest = fm.localModelURL(model.filename)
        availableModels[idx].downloadState = .downloading(progress: 0)

        downloader.download(
            model: model,
            progress: { [weak self] progress in
                Task { @MainActor in
                    self?.availableModels[idx].downloadState = .downloading(progress: progress)
                }
            },
            completion: { [weak self] tempURL in
                Task { @MainActor in
                    guard let self = self else { return }
                    do {
                        try self.fm.moveDownloadedTempFile(temp: tempURL, dest: dest)
                        self.availableModels[idx].downloadState = .downloaded(path: dest)
                    } catch {
                        self.availableModels[idx].downloadState = .failed(error: error.localizedDescription)
                    }
                }
            },
            failure: { [weak self] errorMsg in
                Task { @MainActor in
                    self?.availableModels[idx].downloadState = .failed(error: errorMsg)
                }
            }
        )
    }
}

// MARK: - Delete Model
extension LLMService {

    func deleteModel(_ model: AvailableModel) {
        guard let idx = availableModels.firstIndex(where: { $0.id == model.id }) else { return }

        do {
            try fm.deleteModel(model.filename)
            availableModels[idx].downloadState = .notDownloaded
            availableModels[idx].isSelected = false

            if UserDefaults.standard.string(forKey: selectedModelKey) == model.filename {
                UserDefaults.standard.removeObject(forKey: selectedModelKey)
                llm = nil
                isModelReady = false
            }

        } catch {
            print("Error deleting model: \(error)")
        }
    }
}

// MARK: - Load Model
extension LLMService {

    func loadModel(filename: String) async {
        isModelLoading = true
        isModelReady = false
        llm = nil

        let path = fm.localModelURL(filename)
        guard FileManager.default.fileExists(atPath: path.path) else {
            isModelLoading = false
            return
        }

        let loadedLLM = await loader.loadModel(at: path)

        guard let llmModel = loadedLLM else {
            print("Failed to initialize LLM")
            isModelLoading = false
            return
        }

        self.llm = llmModel
        self.isModelReady = true

        // Update selected model
        for i in availableModels.indices { availableModels[i].isSelected = false }
        if let idx = availableModels.firstIndex(where: { $0.filename == filename }) {
            availableModels[idx].isSelected = true
        }

        UserDefaults.standard.set(filename, forKey: selectedModelKey)
        isModelLoading = false
    }
}

// MARK: - Prompt Builder
extension LLMService {

    private func buildPrompt(_ user: String) -> String {
        return "<|user|>\n\(user)\n<|assistant|>\n"
    }
}

// MARK: - Streaming Message
extension LLMService {

    func sendMessageStream(_ text: String) async -> AsyncStream<String> {

        guard let filename = UserDefaults.standard.string(forKey: selectedModelKey) else {
            return AsyncStream { c in c.yield("No model selected."); c.finish() }
        }

        let path = fm.localModelURL(filename)
        let template = Template.chatML("You are a helpful assistant. Answer concisely and directly.")

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
}

// MARK: - Non-Streaming Message
extension LLMService {

    func sendMessage(_ text: String) async -> String {

        guard let filename = UserDefaults.standard.string(forKey: selectedModelKey) else {
            return "No model selected."
        }

        let path = fm.localModelURL(filename)
        let template = Template.chatML("You are a helpful assistant. Answer concisely and directly. Do not hallucinate.")

        guard let newLLM = LLM(from: path, template: template) else {
            return "Failed to load model."
        }

        self.llm = newLLM

        let prompt = buildPrompt(text)
        await newLLM.respond(to: prompt)

        return newLLM.output.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

// MARK: - Stop Generation
extension LLMService {

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
