//
//  UserDataSettingsView.swift
//  Armory Inventory
//
//  Created by Codex on 4/2/26.
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct UserDataSettingsView: View {
    @Environment(\.modelContext) private var context

    @State private var exportDocument = UserDataDocument(data: Data())
    @State private var isExporting = false
    @State private var isImporting = false
    @State private var pendingImportURL: URL?
    @State private var isShowingImportConfirmation = false
    @State private var isShowingClearConfirmation = false
    @State private var statusMessage: StatusMessage?
    @State private var alertMessage: String?

    private let userDataTransferService: UserDataTransferServicing

    init(userDataTransferService: UserDataTransferServicing = AppServices.shared.resolve()) {
        self.userDataTransferService = userDataTransferService
    }

    var body: some View {
        List {
            Section {
                Text("Export creates a backup file with your inventory and managed settings. Import replaces the current inventory and managed settings with the selected backup.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Section("Backup") {
                Button("Export Data", systemImage: "square.and.arrow.up") {
                    exportData()
                }

                Button("Import Data", systemImage: "square.and.arrow.down") {
                    isImporting = true
                }
                .tint(.orange)
            }

            Section("Danger Zone") {
                Button("Clear All Data", systemImage: "trash") {
                    isShowingClearConfirmation = true
                }
                .tint(.red)
            }

            if let statusMessage {
                Section(statusMessage.title) {
                    Text(statusMessage.message)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("User Data")
        .navigationBarTitleDisplayMode(.inline)
        .fileExporter(
            isPresented: $isExporting,
            document: exportDocument,
            contentType: .json,
            defaultFilename: defaultExportFilename
        ) { result in
            switch result {
            case .success:
                statusMessage = StatusMessage(
                    title: String(localized: "Export Complete"),
                    message: String(localized: "Your backup file was created successfully.")
                )
            case let .failure(error):
                alertMessage = error.localizedDescription
            }
        }
        .fileImporter(
            isPresented: $isImporting,
            allowedContentTypes: [.json]
        ) { result in
            switch result {
            case let .success(url):
                pendingImportURL = url
                isShowingImportConfirmation = true
            case let .failure(error):
                alertMessage = error.localizedDescription
            }
        }
        .alert("Import Backup", isPresented: $isShowingImportConfirmation) {
            Button("Cancel", role: .cancel) {
                clearPendingImportURL()
            }

            Button("Import", role: .destructive) {
                confirmImport()
            }
        } message: {
            Text("Importing a backup will replace your current inventory and managed settings.")
        }
        .alert("Clear All Data", isPresented: $isShowingClearConfirmation) {
            Button("Cancel", role: .cancel) {}

            Button("Clear", role: .destructive) {
                clearAllData()
            }
        } message: {
            Text("Clearing all data will permanently remove your inventory and managed settings.")
        }
        .alert("User Data", isPresented: alertBinding) {
            Button("OK", role: .cancel) {
                alertMessage = nil
            }
        } message: {
            Text(alertMessage ?? "")
        }
    }

    private var alertBinding: Binding<Bool> {
        Binding(
            get: { alertMessage != nil },
            set: { isPresented in
                if !isPresented {
                    alertMessage = nil
                }
            }
        )
    }

    private var defaultExportFilename: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd-HHmmss"
        return "ArmoryInventory-Backup-\(formatter.string(from: .now))"
    }

    private func exportData() {
        do {
            exportDocument = UserDataDocument(data: try userDataTransferService.exportData(from: context))
            isExporting = true
        } catch {
            alertMessage = error.localizedDescription
        }
    }

    private func importData(from url: URL) {
        let didAccess = url.startAccessingSecurityScopedResource()
        defer {
            if didAccess {
                url.stopAccessingSecurityScopedResource()
            }
        }

        do {
            let data = try Data(contentsOf: url)
            try userDataTransferService.importData(data, into: context)
            statusMessage = StatusMessage(
                title: String(localized: "Import Complete"),
                message: String(localized: "The selected backup replaced your current inventory and settings.")
            )
        } catch {
            alertMessage = error.localizedDescription
        }
    }

    private func clearAllData() {
        do {
            try userDataTransferService.clearAllData(in: context)
            statusMessage = StatusMessage(
                title: String(localized: "Data Cleared"),
                message: String(localized: "Your inventory and managed settings were removed.")
            )
        } catch {
            alertMessage = error.localizedDescription
        }
    }

    private func confirmImport() {
        guard let pendingImportURL else {
            return
        }
        importData(from: pendingImportURL)
        clearPendingImportURL()
    }

    private func clearPendingImportURL() {
        pendingImportURL = nil
    }
}

private struct StatusMessage {
    let title: String
    let message: String
}

private struct UserDataDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }

    let data: Data

    init(data: Data) {
        self.data = data
    }

    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else {
            throw CocoaError(.fileReadCorruptFile)
        }
        self.data = data
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
    }
}
