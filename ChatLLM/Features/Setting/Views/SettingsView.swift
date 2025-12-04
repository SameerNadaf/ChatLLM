//
//  SettingsView.swift
//  ChatLLM
//
//  Created by Sameer on 02/12/25.
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var service: LLMService
    
    var body: some View {
        SettingsViewContent(vm: SettingsViewModel(service: service))
            .environmentObject(service)
    }
}

struct SettingsViewContent: View {
    @EnvironmentObject var service: LLMService
    @StateObject var vm: SettingsViewModel
    
    var body: some View {
        List {
            availableModelsSection
            activeModelStatusSection
        }
        .alert("Delete Model?", isPresented: $vm.showDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                vm.confirmDeletion()
            }
        } message: {
            Text("Are you sure you want to delete \(vm.modelToDelete?.name ?? "this model")?")
        }
        .navigationTitle("AI Settings")
        .onAppear {
            AppLogger.log(category: AppLogger.settings, message: "SettingsView appeared.")
        }
    }
}

extension SettingsViewContent {
    var availableModelsSection: some View {
        Section("Available LLM Models") {
            Text("Download a model first, then tap it to activate.")
                .font(.caption)
                .foregroundColor(.secondary)

            ForEach($vm.availableModels) { $model in
                HStack {
                    modelInfo(model)
                    Spacer()
                    modelActionView($model)
                }
                .padding(6)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .contentShape(Rectangle())
            }
        }
    }
}

extension SettingsViewContent {
    func modelInfo(_ model: AvailableModel) -> some View {
        VStack(alignment: .leading) {
            Text(model.name)
                .fontWeight(.medium)
                .lineLimit(1)
                .minimumScaleFactor(0.9)
            
            Text(model.description)
                .font(.caption)
                .lineLimit(1)

            HStack {
                RoundedRectangle(cornerRadius: 6)
                    .foregroundStyle(Color.secondary.opacity(0.12))
                    .frame(width: 60)
                    .overlay { Text(model.size).font(.caption2).padding(4) }

                if model.size.contains("GB") {
                    HStack(spacing: 4) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                            .font(.caption)
                        Text("Heavy")
                            .font(.caption2)
                            .bold()
                            .foregroundColor(.orange)
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 4)
                    .frame(width: 80)
                    .background(Color.orange.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .background {
                        RoundedRectangle(cornerRadius: 6)
                            .stroke()
                            .foregroundStyle(Color.orange)
                    }
                }
            }
            .frame(height: 25)
        }
    }
}

extension SettingsViewContent {
    @ViewBuilder
    func modelActionView(_ model: Binding<AvailableModel>) -> some View {
        switch model.wrappedValue.downloadState {

        case .notDownloaded:
            Button("Download") { vm.download(model.wrappedValue) }
                .buttonStyle(.borderless)

        case .downloading(let progress):
            VStack(alignment: .trailing) {
                Text("\(Int(progress * 100))%").font(.caption)
                ProgressView(value: progress)
                    .progressViewStyle(.linear)
                    .frame(width: 80)
            }

        case .downloaded:
            if model.wrappedValue.isSelected {
                HStack {
                    Text("Selected")
                        .foregroundColor(.green)
                    Button {
                        vm.requestDelete(model.wrappedValue)
                    } label: {
                        Image(systemName: "trash").foregroundColor(.red)
                    }
                    .buttonStyle(.plain)
                }
            } else {
                HStack {
                    Button("Select") {
                        vm.select(model.wrappedValue)
                    }
                    .buttonStyle(.bordered)

                    Button {
                        vm.requestDelete(model.wrappedValue)
                    } label: {
                        Image(systemName: "trash").foregroundColor(.red)
                    }
                    .buttonStyle(.plain)
                }
            }

        case .failed:
            Image(systemName: "xmark.octagon.fill").foregroundColor(.red)
        }
    }
}

extension SettingsViewContent {
    var activeModelStatusSection: some View {
        Section("Active Model Status") {
            HStack {
                Text("Model Status:")
                Spacer()
                if vm.isModelLoading {
                    ProgressView().scaleEffect(0.7)
                    Text("Loading...")
                } else if vm.isModelReady {
                    Text("Ready").foregroundColor(.green)
                } else {
                    Text("Inactive").foregroundColor(.red)
                }
            }

            HStack {
                Text("Current Model:")
                Spacer()
                Text(vm.currentModelName)
            }
        }
    }
}
