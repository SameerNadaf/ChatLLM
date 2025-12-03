//
//  AvailableModel.swift
//  ChatLLM
//
//  Created by CIPL User01 on 03/12/25.
//

import Foundation

enum DownloadState {
    case notDownloaded
    case downloading(progress: Double)
    case downloaded(path: URL)
    case failed(error: String)
}

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
