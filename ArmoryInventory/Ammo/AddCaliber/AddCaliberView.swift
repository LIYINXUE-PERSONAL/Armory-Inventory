//
//  AddCaliberView.swift
//  Armory Inventory
//
//  Created by Yinxue Li on 4/2/26.
//

import SwiftUI
import SwiftData

struct AddCaliberView: View {
    private static let customCaliberOption = "__custom__"

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @AppStorage(CaliberSort.settingsVersionKey) private var sortVersion = 0
    @State private var selectedCaliberName: String = Self.customCaliberOption
    @State private var customName: String = ""
    @State private var existingCalibers: [Caliber] = []
    let viewModel: AddCaliberViewModel

    private let caliberQueryService: CaliberQueryServicing = AppServices.shared.resolve(CaliberQueryServicing.self)

    var body: some View {
        NavigationStack {
            Form {
                Section("Common Calibers") {
                    Picker("Caliber", selection: $selectedCaliberName) {
                        ForEach(commonCaliberNames, id: \.self) { caliberName in
                            Text(caliberName).tag(caliberName)
                        }
                        Text("Custom").tag(Self.customCaliberOption)
                    }
                }
                if selectedCaliberName == Self.customCaliberOption {
                    Section("Custom Caliber") {
                        TextField("Caliber name (e.g., 30-06)", text: $customName)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                    }
                }
                if duplicateExists {
                    Text("That caliber already exists in your inventory.")
                        .font(.footnote)
                        .foregroundStyle(.red)
                }
            }
            .navigationTitle("New Caliber")
            .navigationBarTitleDisplayMode(.inline)
            .task {
                reloadCalibers()
                updateSelectedCaliberNameIfNeeded()
            }
            .onChange(of: existingCalibers.count) {
                updateSelectedCaliberNameIfNeeded()
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") { addCaliber() }
                        .disabled(!canAdd)
                }
            }
        }
    }

    private var selectedName: String {
        viewModel.selectedName(
            selectedCaliberName: selectedCaliberName,
            customName: customName,
            customOption: Self.customCaliberOption
        )
    }

    private var duplicateExists: Bool {
        viewModel.duplicateExists(named: selectedName, in: existingCalibers)
    }

    private var canAdd: Bool {
        viewModel.canAdd(selectedName: selectedName, duplicateExists: duplicateExists)
    }

    private var commonCaliberNames: [String] {
        _ = sortVersion
        return viewModel.commonCaliberNames(excluding: existingCalibers)
    }

    private func addCaliber() {
        guard viewModel.addCaliber(named: selectedName, canAdd: canAdd, to: context) else {
            return
        }
        dismiss()
    }

    private func reloadCalibers() {
        do {
            existingCalibers = try caliberQueryService.fetchCalibers(in: context)
        } catch {
            print("Calibers fetch error: \(error)")
        }
    }

    private func updateSelectedCaliberNameIfNeeded() {
        selectedCaliberName = viewModel.updatedSelectedCaliberName(
            currentSelection: selectedCaliberName,
            customOption: Self.customCaliberOption,
            commonCaliberNames: commonCaliberNames
        )
    }
}
