//
//  AddPartView.swift
//  Armory Inventory
//
//  Created by Codex on 4/5/26.
//

import SwiftUI
import SwiftData

struct AddPartView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @AppStorage(InventorySettingsKeys.accessoriesSalesTaxRate) private var accessoriesTaxRate = 0.0
    @AppStorage(InventorySettingsKeys.showValueInDetails) private var showValueInDetails = true

    let part: Part?
    @State private var brand = ""
    @State private var modelName = ""
    @State private var selectedType: PartType = .barrel
    @State private var customType = ""
    @State private var selectedColor: FirearmColor?
    @State private var customColor = ""
    @State private var purchaseDate = Date.now
    @State private var purchasePriceText = "0.00"
    @State private var notes = ""
    @State private var unlinkFirearm = false
    @State private var isEditing = false

    let viewModel: AddPartViewModel

    init(part: Part? = nil, viewModel: AddPartViewModel) {
        self.part = part
        self.viewModel = viewModel
        _brand = State(initialValue: part?.brand ?? "")
        _modelName = State(initialValue: part?.modelName ?? "")
        _selectedType = State(initialValue: part?.partType ?? .barrel)
        _customType = State(initialValue: part?.partType == .other ? part?.typeDetail ?? "" : "")
        _selectedColor = State(initialValue: part?.partColor)
        _customColor = State(initialValue: part?.partColor == .other ? part?.colorDetail ?? "" : "")
        _purchaseDate = State(initialValue: part?.purchaseDate ?? .now)
        _purchasePriceText = State(initialValue: viewModel.initialPurchasePriceText(for: part))
        _notes = State(initialValue: part?.notes ?? "")
        _unlinkFirearm = State(initialValue: false)
        _isEditing = State(initialValue: part == nil)
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
                    Picker("Part Type", selection: $selectedType) {
                        ForEach(PartType.allCases) { type in
                            Text(type.displayName).tag(type)
                        }
                    }
                    if selectedType == .other {
                        LabeledContent("Type Details") {
                            TextField("", text: $customType)
                                .textInputAutocapitalization(.words)
                                .multilineTextAlignment(.trailing)
                        }
                    }
                }
                .disabled(isReadOnly)

                Section("Configuration") {
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
                        if isEditing {
                            Button(role: .destructive) {
                                unlinkFirearm = true
                            } label: {
                                Text("Unlink Firearm")
                            }
                        }
                    }
                }
            }
            .navigationTitle(part == nil ? "New Part" : "Part Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(primaryButtonTitle) { handlePrimaryAction() }
                        .disabled(isEditing && !canAdd)
                }
            }
        }
    }

    private var resolvedTypeDetail: String? {
        viewModel.resolvedTypeDetail(selectedType: selectedType, customType: customType)
    }

    private var resolvedColorDetail: String? {
        viewModel.resolvedColorDetail(selectedColor: selectedColor, customColor: customColor)
    }

    private var resolvedPurchasePriceCents: Int? {
        viewModel.purchasePriceCents(from: purchasePriceText)
    }

    private var resolvedNotes: String? {
        viewModel.optionalValue(notes)
    }

    private var linkedFirearm: Firearm? {
        viewModel.linkedFirearm(for: part, unlinkFirearm: unlinkFirearm)
    }

    private var purchasePriceWithTaxText: String {
        viewModel.purchasePriceWithTaxText(
            purchasePriceCents: resolvedPurchasePriceCents,
            taxRate: accessoriesTaxRate
        )
    }

    private var isReadOnly: Bool {
        viewModel.isReadOnly(hasPart: part != nil, isEditing: isEditing)
    }

    private var showsPurchaseSection: Bool {
        viewModel.showsPurchaseSection(showValueInDetails: showValueInDetails, isReadOnly: isReadOnly)
    }

    private var primaryButtonTitle: String {
        viewModel.primaryButtonTitle(hasPart: part != nil, isEditing: isEditing)
    }

    private var canAdd: Bool {
        viewModel.canAdd(
            brand: brand,
            modelName: modelName,
            selectedType: selectedType,
            typeDetail: resolvedTypeDetail,
            selectedColor: selectedColor,
            colorDetail: resolvedColorDetail,
            purchasePriceText: purchasePriceText
        )
    }

    private func savePart() {
        guard let purchasePriceCents = resolvedPurchasePriceCents else {
            return
        }

        let didSave: Bool
        if let part {
            didSave = viewModel.updatePart(
                part,
                brand: brand,
                modelName: modelName,
                type: selectedType,
                typeDetail: resolvedTypeDetail,
                color: selectedColor,
                colorDetail: resolvedColorDetail,
                purchaseDate: purchaseDate,
                purchasePriceCents: purchasePriceCents,
                notes: resolvedNotes,
                firearm: linkedFirearm,
                canSave: canAdd,
                in: context
            )
        } else {
            didSave = viewModel.addPart(
                brand: brand,
                modelName: modelName,
                type: selectedType,
                typeDetail: resolvedTypeDetail,
                color: selectedColor,
                colorDetail: resolvedColorDetail,
                purchaseDate: purchaseDate,
                purchasePriceCents: purchasePriceCents,
                notes: resolvedNotes,
                firearm: nil,
                canAdd: canAdd,
                to: context
            )
        }

        guard didSave else {
            return
        }

        if part == nil {
            dismiss()
        } else {
            isEditing = false
        }
    }

    private func handlePrimaryAction() {
        if part != nil && !isEditing {
            isEditing = true
            return
        }
        savePart()
    }
}
