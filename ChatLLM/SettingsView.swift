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
        List {
            Section("Available LLM Models") {
                Text("Download a model first, then tap it to activate.")
                    .font(.caption)
                    .foregroundColor(.secondary)

                ForEach($service.availableModels) { $model in

                    HStack {
                        VStack(alignment: .leading) {
                            Text(model.name)
                                .fontWeight(.medium)
                            
                            Text(model.description)
                                .font(.caption)
                            
                            HStack {
                                RoundedRectangle(cornerRadius: 6)
                                    .foregroundStyle(Color.secondary.opacity(0.12))
                                    .frame(width: 60)
                                    .overlay(alignment: .center) {
                                        Text(model.size)
                                            .font(.caption2)
                                            .padding(4)
                                    }
                                    
                                    
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

                        Spacer()

                        modelActionView(model: $model)
                    }
                    .padding(6)
//                    .background(model.isSelected ? Color.accentColor.opacity(0.15) : Color.clear)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .contentShape(Rectangle())
                    .onTapGesture {
                        switch model.downloadState {
                        case .downloaded:
                            AppLogger.log(category: AppLogger.settings, message: "User tapped row for downloaded model: \(model.name)")
                            withAnimation {
                                Task { await service.loadModel(filename: model.filename) }
                            }
                        default:
                            AppLogger.log(category: AppLogger.settings, message: "User tapped row for model (not downloaded): \(model.name)")
                        }
                    }
                }
            }

            Section("Active Model Status") {
                HStack {
                    Text("Model Status:")
                    Spacer()
                    if service.isModelLoading {
                        ProgressView().scaleEffect(0.7)
                        Text("Loading...")
                    } else if service.isModelReady {
                        Text("Ready").foregroundColor(.green)
                    } else {
                        Text("Inactive").foregroundColor(.red)
                    }
                }

                HStack {
                    Text("Current Model:")
                    Spacer()
                    Text(service.availableModels.first(where: { $0.isSelected })?.name ?? "None")
                }
            }
        }
        .navigationTitle("AI Settings")
        .onAppear {
            AppLogger.log(category: AppLogger.settings, message: "SettingsView appeared.")
        }
    }

    // MARK: - Download/Action Buttons
    @ViewBuilder
    func modelActionView(model: Binding<AvailableModel>) -> some View {
        switch model.wrappedValue.downloadState {

        case .notDownloaded:
            Button("Download") {
                AppLogger.log(category: AppLogger.settings, message: "User tapped Download button for: \(model.wrappedValue.name)")
                service.downloadModel(model.wrappedValue)
            }
            .buttonStyle(.borderless)

        case .downloading(let progress):
            VStack(alignment: .trailing) {
                Text("\(Int(progress * 100))%")
                    .font(.caption)
                ProgressView(value: progress)
                    .progressViewStyle(.linear)
                    .frame(width: 80)
            }

        case .downloaded:
            if model.wrappedValue.isSelected {
                Text("selected")
                    .foregroundColor(.green)
            } else {
                Button("Select") {
                    AppLogger.log(category: AppLogger.settings, message: "User tapped Select button for: \(model.wrappedValue.name)")
                    Task { await service.loadModel(filename: model.wrappedValue.filename) }
                }
                .buttonStyle(.borderless)
            }

        case .failed:
            Image(systemName: "xmark.octagon.fill")
                .foregroundColor(.red)
        }
    }
}
