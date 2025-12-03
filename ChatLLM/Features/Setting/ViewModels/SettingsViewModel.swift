//
//  SettingsViewModel.swift
//  ChatLLM
//
//  Created by Sameer on 03/12/25.
//

import SwiftUI

@MainActor
class SettingsViewModel: ObservableObject {
    @Published var showDeleteAlert = false
    @Published var modelToDelete: AvailableModel? = nil
    
    @Published var availableModels: [AvailableModel] = []
    @Published var isModelLoading: Bool = false
    @Published var isModelReady: Bool = false
    @Published var currentModelName: String = "None"
    
    private let service: LLMService
    
    init(service: LLMService) {
        self.service = service
        
        // Initial bindings
        self.availableModels = service.availableModels
        self.isModelLoading = service.isModelLoading
        self.isModelReady = service.isModelReady
        self.currentModelName = service.availableModels.first(where: { $0.isSelected })?.name ?? "None"
        
        observeServiceChanges()
    }
}

extension SettingsViewModel {
    
    // Sync with EnvironmentObject updates
    private func observeServiceChanges() {
        service.$availableModels
            .receive(on: DispatchQueue.main)
            .assign(to: &$availableModels)
        
        service.$isModelLoading
            .receive(on: DispatchQueue.main)
            .assign(to: &$isModelLoading)
        
        service.$isModelReady
            .receive(on: DispatchQueue.main)
            .assign(to: &$isModelReady)
        
        service.$availableModels
            .map { list in list.first(where: { $0.isSelected })?.name ?? "None" }
            .receive(on: DispatchQueue.main)
            .assign(to: &$currentModelName)
    }
    
    // MARK: - User Actions
    
    func tapModelRow(_ model: AvailableModel) {
        switch model.downloadState {
        case .downloaded:
            Task { await service.loadModel(filename: model.filename) }
        default:
            break
        }
    }
    
    func requestDelete(_ model: AvailableModel) {
        modelToDelete = model
        showDeleteAlert = true
    }
    
    func confirmDeletion() {
        guard let model = modelToDelete else { return }
        service.deleteModel(model)
    }
    
    func download(_ model: AvailableModel) {
        service.downloadModel(model)
    }
    
    func select(_ model: AvailableModel) {
        Task { await service.loadModel(filename: model.filename) }
    }
}
