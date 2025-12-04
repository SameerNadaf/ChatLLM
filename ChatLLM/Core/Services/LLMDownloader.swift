//
//  LLMDownloader.swift
//  ChatLLM
//
//  Created by CIPL User01 on 03/12/25.
//

import Foundation

/// Handles downloading of LLM models from remote URLs.
final class LLMDownloader {

    /// Downloads a model file from the specified URL.
    /// - Parameters:
    ///   - model: The model to download.
    ///   - progress: A closure called periodically with the download progress (0.0 to 1.0).
    ///   - completion: A closure called with the local URL of the downloaded file upon success.
    ///   - failure: A closure called with an error message upon failure.
    func download(
        model: AvailableModel,
        progress: @escaping (Double) -> Void,
        completion: @escaping (URL) -> Void,
        failure: @escaping (String) -> Void
    ) {

        var request = URLRequest(url: model.downloadUrl)
        request.setValue("Mozilla/5.0", forHTTPHeaderField: "User-Agent")

        let delegate = DownloadDelegate(
            onProgress: progress,
            onComplete: completion,
            onError: { err in failure(err.localizedDescription) }
        )

        let session = URLSession(
            configuration: .default,
            delegate: delegate,
            delegateQueue: nil
        )

        session.downloadTask(with: request).resume()
    }
}

/// Delegate for handling URLSession download events.
final class DownloadDelegate: NSObject, URLSessionDownloadDelegate {
    let onProgress: (Double) -> Void
    let onComplete: (URL) -> Void
    let onError: (Error) -> Void

    /// Initializes the download delegate.
    /// - Parameters:
    ///   - onProgress: Callback for progress updates.
    ///   - onComplete: Callback for successful completion.
    ///   - onError: Callback for errors.
    init(
        onProgress: @escaping (Double) -> Void,
        onComplete: @escaping (URL) -> Void,
        onError: @escaping (Error) -> Void
    ) {
        self.onProgress = onProgress
        self.onComplete = onComplete
        self.onError = onError
    }

    func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didWriteData bytesWritten: Int64,
        totalBytesWritten: Int64,
        totalBytesExpectedToWrite: Int64
    ) {
        guard totalBytesExpectedToWrite > 0 else { return }
        onProgress(Double(totalBytesWritten) / Double(totalBytesExpectedToWrite))
    }

    func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didFinishDownloadingTo location: URL
    ) {
        let safeTempURL = FileManager.default
            .temporaryDirectory
            .appendingPathComponent(UUID().uuidString)

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

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error { onError(error) }
    }
}

