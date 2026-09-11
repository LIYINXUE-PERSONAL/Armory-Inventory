//
//  AddMagazineView.swift
//  Armory Inventory
//
//  Created by Codex on 4/2/26.
//

import SwiftUI
import SwiftData

struct AddMagazineView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @AppStorage(InventorySettingsKeys.accessoriesSalesTaxRate) private var accessoriesTaxRate = 0.0
    @AppStorage(InventorySettingsKeys.showValueInDetails) private var showValueInDetails = true

    let magazine: Magazine?
    @State private var brand = ""
    @State private var modelName = ""
    @State private var countText = "1"
    @State private var capacityText = ""
    @State private var selectedPatternSelection: MagazinePatternSelection = .custom
    @State private var manualPatternName = ""
    @State private var selectedCompatibleCaliberNames: Set<String> = []
    @State private var selectedColor: FirearmColor?
    @State private var customColor = ""
    @State private var purchaseDate = Date.now
    @State private var purchasePriceText = "0.00"
    @State private var notes = ""
    @State private var unlinkFirearm = false
    @State private var isEditing = false
    @State private var deletionErrorMessage: String?
    @State private var calibers: [Caliber] = []
    @State private var savedCustomPatterns: [MagazinePattern] = []
    @State private var editingCustomPatternID: UUID?

    let viewModel: AddMagazineViewModel
    private let caliberQueryService: CaliberQueryServicing
    
    init(
        magazine: Magazine? = nil,
        viewModel: AddMagazineViewModel,
        caliberQueryService: CaliberQueryServicing = AppServices.shared.resolve(CaliberQueryServicing.self)
    ) {
        self.magazine = magazine
        self.viewModel = viewModel
        self.caliberQueryService = caliberQueryService
        _brand = State(initialValue: magazine?.brand ?? "")
        _modelName = State(initialValue: magazine?.modelName ?? "")
        _countText = State(initialValue: magazine.map { String($0.count) } ?? "1")
        _capacityText = State(initialValue: magazine.map { String($0.capacity) } ?? "")
        _selectedPatternSelection = State(initialValue: viewModel.initialPatternSelection(for: magazine))
        _manualPatternName = State(initialValue: viewModel.initialManualPatternName(for: magazine))
        _selectedCompatibleCaliberNames = State(initialValue: viewModel.initialCompatibleCaliberNames(for: magazine))
        _selectedColor = State(initialValue: magazine?.magazineColor)
        _customColor = State(initialValue: magazine?.magazineColor == .other ? magazine?.colorDetail ?? "" : "")
        _purchaseDate = State(initialValue: magazine?.purchaseDate ?? .now)
        _purchasePriceText = State(initialValue: viewModel.initialPurchasePriceText(for: magazine))
        _notes = State(initialValue: magazine?.notes ?? "")
        _unlinkFirearm = State(initialValue: false)
        _isEditing = State(initialValue: magazine == nil)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Basic Info") {
                    LabeledContent("Brand") {
                        TextField("", text: $brand)
                            .textInputAutocapitalization(.words)
                            .multilineTextAlignment(.trailing)
                    }
                    LabeledContent("Model Name") {
                        TextField("", text: $modelName)
                            .textInputAutocapitalization(.words)
                            .multilineTextAlignment(.trailing)
                    }
                    LabeledContent("Count") {
                        TextField("1", text: $countText)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                    }
                }
                .disabled(isReadOnly)

                Section("Configuration") {
                    LabeledContent("Pattern") {
                        Menu {
                            if !suggestedCatalogPatterns.isEmpty {
                                Section("Suggested Catalog Patterns") {
                                    ForEach(suggestedCatalogPatterns) { pattern in
                                        Button {
                                            editingCustomPatternID = nil
                                            selectedPatternSelection = .catalog(pattern.id)
                                        } label: {
                                            patternSelectionLabel(
                                                title: pattern.displayName,
                                                isSelected: selectedPatternSelection == .catalog(pattern.id)
                                            )
                                        }
                                    }
                                }
                            }

                            if !additionalCatalogPatterns.isEmpty {
                                Section("Other Catalog Patterns") {
                                    ForEach(additionalCatalogPatterns) { pattern in
                                        Button {
                                            editingCustomPatternID = nil
                                            selectedPatternSelection = .catalog(pattern.id)
                                        } label: {
                                            patternSelectionLabel(
                                                title: pattern.displayName,
                                                isSelected: selectedPatternSelection == .catalog(pattern.id)
                                            )
                                        }
                                    }
                                }
                            }

                            if !savedCustomPatterns.isEmpty {
                                Section("Saved Custom Patterns") {
                                    ForEach(savedCustomPatterns) { pattern in
                                        Button {
                                            editingCustomPatternID = nil
                                            selectedPatternSelection = .existingCustom(pattern)
                                        } label: {
                                            patternSelectionLabel(
                                                title: pattern.displayName,
                                                isSelected: selectedPatternSelection == .existingCustom(pattern)
                                            )
                                        }
                                    }
                                }
                            }

                            Section("Custom Patterns") {
                                Button {
                                    editingCustomPatternID = nil
                                    selectedPatternSelection = .custom
                                } label: {
                                    patternSelectionLabel(
                                        title: "Custom Pattern",
                                        isSelected: selectedPatternSelection == .custom
                                    )
                                }
                            }
                        } label: {
                            HStack(spacing: 6) {
                                Text(selectedPatternTitle)
                                    .foregroundStyle(.primary)
                                Image(systemName: "chevron.down")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .buttonStyle(.plain)
                    }

                    Text(selectedPatternDescription)
                        .font(.footnote)
                        .foregroundStyle(.secondary)

                    if selectedPatternSelection.requiresManualName {
                        LabeledContent(selectedPatternSelection == .legacy ? "Legacy Name" : "Custom Name") {
                            TextField("", text: $manualPatternName)
                                .multilineTextAlignment(.trailing)
                        }
                    }

                    if case let .existingCustom(pattern) = selectedPatternSelection, isEditing {
                        Button {
                            beginEditingCustomPattern(pattern)
                        } label: {
                            Text("Edit Saved Pattern")
                        }
                    }

                    if selectedPatternSelection.allowsManualCaliberSelection {
                        LabeledContent("Compatible Calibers") {
                            Menu {
                                ForEach(calibers) { caliber in
                                    Button {
                                        toggleCompatibleCaliberSelection(for: caliber.name)
                                    } label: {
                                        patternSelectionLabel(
                                            title: caliber.name,
                                            isSelected: selectedCompatibleCaliberNames.contains(caliber.name)
                                        )
                                    }
                                }
                            } label: {
                                HStack(spacing: 6) {
                                    Text(selectedCompatibleCaliberSummary)
                                        .foregroundStyle(selectedCompatibleCaliberNames.isEmpty ? .secondary : .primary)
                                    Image(systemName: "chevron.down")
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    } else {
                        LabeledContent("Compatible Calibers", value: selectedCompatibleCaliberSummary)
                    }

                    LabeledContent("Capacity") {
                        TextField("", text: $capacityText)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                    }

                    Picker("Color", selection: $selectedColor) {
                        Text("None").tag(nil as FirearmColor?)
                        ForEach(FirearmColor.allCases) { color in
                            Text(color.displayName).tag(Optional(color))
                        }
                    }

                    if selectedColor == .other {
                        LabeledContent("Color Details") {
                            TextField("", text: $customColor)
                                .multilineTextAlignment(.trailing)
                        }
                    }
                }
                .disabled(isReadOnly)

                if showsPurchaseSection {
                    Section("Purchase") {
                        DatePicker("Purchase date", selection: $purchaseDate, displayedComponents: .date)
                        LabeledContent("Purchase Price") {
                            SelectAllTextField(
                                placeholder: "",
                                text: $purchasePriceText,
                                keyboardType: .decimalPad,
                                textAlignment: .right
                            )
                        }
                        Text("With \(accessoriesTaxRate.formatted(.number.precision(.fractionLength(0...2))))% accessories tax: \(purchasePriceWithTaxText)")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    .disabled(isReadOnly)
                }

                Section("Notes") {
                    TextField("Notes (optional)", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
                .disabled(isReadOnly)

                if let linkedFirearm = linkedFirearm {
                    Section("Linked Firearm") {
                        Text(linkedFirearm.displayName)
                        if let compatibilityMessage {
                            Text(compatibilityMessage)
                                .font(.footnote)
                                .foregroundStyle(.red)
                        }
                        if isEditing {
                            Button(role: .destructive) {
                                unlinkFirearm = true
                            } label: {
                                Text("Unlink Firearm")
                            }
                        }
                    }
                }
                if magazine != nil {
                    Section {
                        Button("Delete Magazine", role: .destructive) {
                            deleteMagazine()
                        }
                    }
                }
            }
            .navigationTitle(magazine == nil ? "New Magazine" : "Magazine Details")
            .navigationBarTitleDisplayMode(.inline)
            .task {
                reloadPickerData()
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(primaryButtonTitle) { handlePrimaryAction() }
                        .disabled(isEditing && !canAdd)
                }
            }
            .alert("Magazine Cannot Be Deleted", isPresented: deletionErrorBinding) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(deletionErrorMessage ?? "")
            }
        }
    }

    private var resolvedColorDetail: String? {
        viewModel.resolvedColorDetail(selectedColor: selectedColor, customColor: customColor)
    }

    private func deleteMagazine() {
        guard let magazine else { return }
        let result = viewModel.deleteMagazine(magazine, in: context)
        if result.isValid {
            dismiss()
        } else {
            deletionErrorMessage = result.message
        }
    }

    private var deletionErrorBinding: Binding<Bool> {
        Binding(
            get: { deletionErrorMessage != nil },
            set: { if !$0 { deletionErrorMessage = nil } }
        )
    }

    private var resolvedCount: Int? {
        viewModel.count(from: countText)
    }

    private var resolvedCapacity: Int? {
        viewModel.capacity(from: capacityText)
    }

    private var resolvedPurchasePriceCents: Int? {
        viewModel.purchasePriceCents(from: purchasePriceText)
    }

    private var resolvedNotes: String? {
        viewModel.optionalValue(notes)
    }

    private var linkedFirearm: Firearm? {
        viewModel.linkedFirearm(for: magazine, unlinkFirearm: unlinkFirearm)
    }

    private var purchasePriceWithTaxText: String {
        viewModel.purchasePriceWithTaxText(
            purchasePriceCents: resolvedPurchasePriceCents,
            taxRate: accessoriesTaxRate
        )
    }

    private var isReadOnly: Bool {
        viewModel.isReadOnly(hasMagazine: magazine != nil, isEditing: isEditing)
    }

    private var showsPurchaseSection: Bool {
        viewModel.showsPurchaseSection(showValueInDetails: showValueInDetails, isReadOnly: isReadOnly)
    }

    private var primaryButtonTitle: String {
        viewModel.primaryButtonTitle(hasMagazine: magazine != nil, isEditing: isEditing)
    }

    private var canAdd: Bool {
        viewModel.canAdd(
            brand: brand,
            modelName: modelName,
            countText: countText,
            capacityText: capacityText,
            selectedColor: selectedColor,
            colorDetail: resolvedColorDetail,
            purchasePriceText: purchasePriceText,
            patternSelection: selectedPatternSelection,
            manualPatternName: manualPatternName,
            compatibleCaliberNames: selectedCompatibleCaliberNames,
            firearm: linkedFirearm,
            existingMagazine: magazine
        )
    }

    private var compatibilityMessage: String? {
        viewModel.compatibilityValidationResult(
            patternSelection: selectedPatternSelection,
            manualPatternName: manualPatternName,
            brand: brand,
            modelName: modelName,
            compatibleCaliberNames: selectedCompatibleCaliberNames,
            firearm: linkedFirearm,
            existingMagazine: magazine
        ).message
    }

    private var suggestedCatalogPatterns: [MagazinePattern] {
        viewModel.suggestedCatalogPatterns(firearm: linkedFirearm)
    }

    private var additionalCatalogPatterns: [MagazinePattern] {
        viewModel.additionalCatalogPatterns(firearm: linkedFirearm)
    }

    private var selectedPatternTitle: String {
        viewModel.selectedPatternTitle(
            selection: selectedPatternSelection,
            manualPatternName: manualPatternName,
            brand: brand,
            modelName: modelName,
            compatibleCaliberNames: selectedCompatibleCaliberNames,
            firearm: linkedFirearm,
            existingMagazine: magazine
        )
    }

    private var selectedPatternDescription: String {
        viewModel.selectedPatternDescription(
            selection: selectedPatternSelection,
            manualPatternName: manualPatternName,
            brand: brand,
            modelName: modelName,
            compatibleCaliberNames: selectedCompatibleCaliberNames,
            firearm: linkedFirearm,
            existingMagazine: magazine
        )
    }

    private var selectedCompatibleCaliberSummary: String {
        let names = viewModel.resolvedSupportedCaliberNames(
            selection: selectedPatternSelection,
            manualPatternName: manualPatternName,
            brand: brand,
            modelName: modelName,
            compatibleCaliberNames: selectedCompatibleCaliberNames,
            firearm: linkedFirearm,
            existingMagazine: magazine
        )
        guard !names.isEmpty else {
            return selectedPatternSelection.allowsManualCaliberSelection
                ? String(localized: "None")
                : String(localized: "No Caliber")
        }

        return names.joined(separator: ", ")
    }

    private func saveMagazine() {
        guard let count = resolvedCount,
              let capacity = resolvedCapacity,
              let purchasePriceCents = resolvedPurchasePriceCents else {
            return
        }

        let didSave: Bool
        if let magazine {
            didSave = viewModel.updateMagazine(
                magazine,
                brand: brand,
                modelName: modelName,
                count: count,
                capacity: capacity,
                purchaseDate: purchaseDate,
                purchasePriceCents: purchasePriceCents,
                color: selectedColor,
                colorDetail: resolvedColorDetail,
                notes: resolvedNotes,
                patternSelection: selectedPatternSelection,
                manualPatternName: manualPatternName,
                compatibleCaliberNames: selectedCompatibleCaliberNames,
                existingCustomPatternIDOverride: editingCustomPatternID,
                firearm: linkedFirearm,
                canSave: canAdd,
                in: context
            )
        } else {
            didSave = viewModel.addMagazine(
                brand: brand,
                modelName: modelName,
                count: count,
                capacity: capacity,
                purchaseDate: purchaseDate,
                purchasePriceCents: purchasePriceCents,
                color: selectedColor,
                colorDetail: resolvedColorDetail,
                notes: resolvedNotes,
                patternSelection: selectedPatternSelection,
                manualPatternName: manualPatternName,
                compatibleCaliberNames: selectedCompatibleCaliberNames,
                existingCustomPatternIDOverride: editingCustomPatternID,
                firearm: nil,
                canAdd: canAdd,
                to: context
            )
        }

        guard didSave else {
            return
        }

        if magazine == nil {
            dismiss()
        } else {
            isEditing = false
        }
    }

    private func handlePrimaryAction() {
        if magazine != nil && !isEditing {
            isEditing = true
            return
        }
        saveMagazine()
    }

    private func toggleCompatibleCaliberSelection(for caliberName: String) {
        selectedCompatibleCaliberNames = viewModel.toggledCompatibleCaliberSelection(
            currentSelection: selectedCompatibleCaliberNames,
            caliberName: caliberName,
            isEditing: isEditing
        )
    }

    private func reloadCalibers() {
        do {
            calibers = try caliberQueryService.fetchCalibers(in: context)
        } catch {
            print("Calibers fetch error: \(error)")
        }
    }

    private func reloadPickerData() {
        reloadCalibers()
        savedCustomPatterns = viewModel.availableCustomPatterns(in: context)
    }

    private func beginEditingCustomPattern(_ pattern: MagazinePattern) {
        selectedPatternSelection = .custom
        manualPatternName = pattern.displayName
        selectedCompatibleCaliberNames = Set(pattern.compatibility.supportedCaliberNames)
        editingCustomPatternID = viewModel.customPatternUUID(from: pattern.id)
    }

    @ViewBuilder
    private func patternSelectionLabel(title: String, isSelected: Bool) -> some View {
        if isSelected {
            Label(title, systemImage: "checkmark")
        } else {
            Text(title)
        }
    }
}
