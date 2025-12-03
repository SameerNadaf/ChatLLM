//
//  LLMDownloader.swift
//  ChatLLM
//
//  Created by CIPL User01 on 03/12/25.
//

import Foundation

final class LLMDownloader {

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

final class DownloadDelegate: NSObject, URLSessionDownloadDelegate {
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

