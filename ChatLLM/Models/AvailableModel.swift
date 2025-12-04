//
//  AvailableModel.swift
//  ChatLLM
//
//  Created by CIPL User01 on 03/12/25.
//

import Foundation

/// Represents the current state of a model download.
enum DownloadState {
    /// The model has not been downloaded yet.
    case notDownloaded
    /// The model is currently being downloaded with the given progress (0.0 to 1.0).
    case downloading(progress: Double)
    /// The model has been successfully downloaded and is available at the specified local URL.
    case downloaded(path: URL)
    /// The model download failed with an error message.
    case failed(error: String)
}

/// Represents a Large Language Model available for use in the application.
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
