//
//  AddAttachmentView.swift
//  Armory Inventory
//
//  Created by Codex on 4/2/26.
//

import SwiftUI
import SwiftData

struct AddAttachmentView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @AppStorage(InventorySettingsKeys.accessoriesSalesTaxRate) private var accessoriesTaxRate = 0.0
    @AppStorage(InventorySettingsKeys.showValueInDetails) private var showValueInDetails = true

    let attachment: Attachment?
    @State private var brand = ""
    @State private var modelName = ""
    @State private var selectedType: AttachmentType = .stock
    @State private var customType = ""
    @State private var selectedColor: FirearmColor?
    @State private var customColor = ""
    @State private var purchaseDate = Date.now
    @State private var purchasePriceText = "0.00"
    @State private var notes = ""
    @State private var unlinkFirearm = false
    @State private var isEditing = false

    let viewModel: AddAttachmentViewModel

    init(attachment: Attachment? = nil, viewModel: AddAttachmentViewModel) {
        self.attachment = attachment
        self.viewModel = viewModel
        _brand = State(initialValue: attachment?.brand ?? "")
        _modelName = State(initialValue: attachment?.modelName ?? "")
        _selectedType = State(initialValue: attachment?.attachmentType ?? .stock)
        _customType = State(initialValue: attachment?.attachmentType == .other ? attachment?.typeDetail ?? "" : "")
        _selectedColor = State(initialValue: attachment?.attachmentColor)
        _customColor = State(initialValue: attachment?.attachmentColor == .other ? attachment?.colorDetail ?? "" : "")
        _purchaseDate = State(initialValue: attachment?.purchaseDate ?? .now)
        _purchasePriceText = State(initialValue: viewModel.initialPurchasePriceText(for: attachment))
        _notes = State(initialValue: attachment?.notes ?? "")
        _unlinkFirearm = State(initialValue: false)
        _isEditing = State(initialValue: attachment == nil)
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
                    Picker("Attachment Type", selection: $selectedType) {
                        ForEach(AttachmentType.allCases) { type in
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
                        TextField("Purchase price (USD)", text: $purchasePriceText)
                            .keyboardType(.decimalPad)
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
            .navigationTitle(attachment == nil ? "New Attachment" : "Attachment Details")
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
        viewModel.linkedFirearm(for: attachment, unlinkFirearm: unlinkFirearm)
    }

    private var purchasePriceWithTaxText: String {
        viewModel.purchasePriceWithTaxText(
            purchasePriceCents: resolvedPurchasePriceCents,
            taxRate: accessoriesTaxRate
        )
    }

    private var isReadOnly: Bool {
        viewModel.isReadOnly(hasAttachment: attachment != nil, isEditing: isEditing)
    }

    private var showsPurchaseSection: Bool {
        viewModel.showsPurchaseSection(showValueInDetails: showValueInDetails, isReadOnly: isReadOnly)
    }

    private var primaryButtonTitle: String {
        viewModel.primaryButtonTitle(hasAttachment: attachment != nil, isEditing: isEditing)
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

    private func saveAttachment() {
        guard let purchasePriceCents = resolvedPurchasePriceCents else {
            return
        }

        let didSave: Bool
        if let attachment {
            didSave = viewModel.updateAttachment(
                attachment,
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
            didSave = viewModel.addAttachment(
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

        if attachment == nil {
            dismiss()
        } else {
            isEditing = false
        }
    }

    private func handlePrimaryAction() {
        if attachment != nil && !isEditing {
            isEditing = true
            return
        }
        saveAttachment()
    }
}
