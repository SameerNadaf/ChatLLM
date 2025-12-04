//
//  SettingsViewModel.swift
//  ChatLLM
//
//  Created by Sameer on 03/12/25.
//

import SwiftUI

/// ViewModel managing the state and logic for the Settings view.
@MainActor
class SettingsViewModel: ObservableObject {
    /// Controls the visibility of the delete confirmation alert.
    @Published var showDeleteAlert = false
    /// The model currently selected for deletion.
    @Published var modelToDelete: AvailableModel? = nil
    
    /// The list of available models, synced with the service.
    @Published var availableModels: [AvailableModel] = []
    /// Indicates if a model is currently loading.
    @Published var isModelLoading: Bool = false
    /// Indicates if a model is ready for use.
    @Published var isModelReady: Bool = false
    /// The name of the currently selected model.
    @Published var currentModelName: String = "None"
    
    private let service: LLMService
    
    /// Initializes the SettingsViewModel with the shared LLM service.
    /// - Parameter service: The LLMService instance.
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
    /// Sets up subscriptions to observe changes in the LLM service and update the view model's state.
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
    
    /// Prepares a model for deletion by setting the state and showing the confirmation alert.
    /// - Parameter model: The model to be deleted.
    func requestDelete(_ model: AvailableModel) {
        modelToDelete = model
        showDeleteAlert = true
    }
    
    /// Confirms the deletion of the selected model.
    func confirmDeletion() {
        guard let model = modelToDelete else { return }
        service.deleteModel(model)
    }
    
    /// Initiates the download of a model.
    /// - Parameter model: The model to download.
    func download(_ model: AvailableModel) {
        service.downloadModel(model)
    }
    
    /// Selects a model to be loaded and used.
    /// - Parameter model: The model to select.
    func select(_ model: AvailableModel) {
        Task { await service.loadModel(filename: model.filename) }
    }
}
