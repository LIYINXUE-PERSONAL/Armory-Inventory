//
//  AddOpticView.swift
//  Armory Inventory
//
//  Created by Codex on 4/2/26.
//

import SwiftUI
import SwiftData

struct AddOpticView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @AppStorage(InventorySettingsKeys.accessoriesSalesTaxRate) private var accessoriesTaxRate = 0.0
    @AppStorage(InventorySettingsKeys.showValueInDetails) private var showValueInDetails = true

    let optic: Optic?
    @State private var brand = ""
    @State private var modelName = ""
    @State private var serialNumber = ""
    @State private var selectedType: OpticType = .redDot
    @State private var isFixedMagnification = true
    @State private var fixedMagnificationText = ""
    @State private var minMagnificationText = ""
    @State private var maxMagnificationText = ""
    @State private var selectedFootprint: OpticFootprint = .picatinny
    @State private var customFootprint = ""
    @State private var tubeSizeText = ""
    @State private var reticle = ""
    @State private var selectedFocalPlane: OpticFocalPlane?
    @State private var isIlluminated = false
    @State private var selectedColor: FirearmColor?
    @State private var customColor = ""
    @State private var purchaseDate = Date.now
    @State private var purchasePriceText = "0.00"
    @State private var notes = ""
    @State private var unlinkFirearm = false
    @State private var isEditing = false
    @State private var existingOptics: [Optic] = []

    let viewModel: AddOpticViewModel
    private let opticLookupService: OpticLookupServicing

    init(
        optic: Optic? = nil,
        viewModel: AddOpticViewModel,
        opticLookupService: OpticLookupServicing = AppServices.shared.resolve(OpticLookupServicing.self)
    ) {
        self.optic = optic
        self.viewModel = viewModel
        self.opticLookupService = opticLookupService
        _brand = State(initialValue: optic?.brand ?? "")
        _modelName = State(initialValue: optic?.modelName ?? "")
        _serialNumber = State(initialValue: optic?.serialNumber ?? "")
        let initialType = optic?.opticType ?? .redDot
        _selectedType = State(initialValue: initialType)
        let isFixed = optic.map { $0.minMagnification == $0.maxMagnification } ?? true
        _isFixedMagnification = State(initialValue: isFixed)
        _fixedMagnificationText = State(
            initialValue: isFixed ? optic.map { viewModel.formattedNumericInput($0.maxMagnification) } ?? "" : ""
        )
        _minMagnificationText = State(
            initialValue: isFixed ? "" : optic.map { viewModel.formattedNumericInput($0.minMagnification) } ?? ""
        )
        _maxMagnificationText = State(
            initialValue: isFixed ? "" : optic.map { viewModel.formattedNumericInput($0.maxMagnification) } ?? ""
        )
        _selectedFootprint = State(initialValue: optic?.opticFootprint ?? initialType.defaultFootprint ?? .other)
        _customFootprint = State(initialValue: optic?.opticFootprint == .other ? optic?.footprintDetail ?? "" : "")
        _tubeSizeText = State(
            initialValue: optic?.tubeSizeMillimeters.map { viewModel.formattedNumericInput($0) } ?? ""
        )
        _reticle = State(initialValue: optic?.reticle ?? "")
        _selectedFocalPlane = State(initialValue: optic?.opticFocalPlane)
        _isIlluminated = State(initialValue: optic?.isIlluminated ?? false)
        _selectedColor = State(initialValue: optic?.opticColor)
        _customColor = State(initialValue: optic?.opticColor == .other ? optic?.colorDetail ?? "" : "")
        _purchaseDate = State(initialValue: optic?.purchaseDate ?? .now)
        _purchasePriceText = State(initialValue: viewModel.initialPurchasePriceText(for: optic))
        _notes = State(initialValue: optic?.notes ?? "")
        _unlinkFirearm = State(initialValue: false)
        _isEditing = State(initialValue: optic == nil)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Basic Info") {
                    TextField("Brand", text: $brand)
                        .textInputAutocapitalization(.words)
                    TextField("Model name", text: $modelName)
                        .textInputAutocapitalization(.words)
                    TextField("Serial number (optional)", text: $serialNumber)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                    if duplicateExists {
                        Text("That serial number already exists in your inventory.")
                            .font(.footnote)
                            .foregroundStyle(.red)
                    }
                }
                .disabled(isReadOnly)

                Section("Configuration") {
                    Picker("Type", selection: $selectedType) {
                        ForEach(OpticType.allCases) { opticType in
                            Text(opticType.displayName).tag(opticType)
                        }
                    }
                    .onChange(of: selectedType) {
                        let updatedSelection = viewModel.updatedFootprintSelection(
                            selectedType: selectedType,
                            selectedFootprint: selectedFootprint,
                            customFootprint: customFootprint
                        )
                        selectedFootprint = updatedSelection.footprint
                        customFootprint = updatedSelection.customFootprint
                    }

                    Picker("Magnification", selection: $isFixedMagnification) {
                        Text("Fixed").tag(true)
                        Text("Variable").tag(false)
                    }
                    .pickerStyle(.segmented)

                    if isFixedMagnification {
                        TextField("Magnification", text: $fixedMagnificationText)
                            .keyboardType(.decimalPad)
                    } else {
                        HStack(spacing: 12) {
                            TextField("Min", text: $minMagnificationText)
                                .keyboardType(.decimalPad)
                            Divider()
                                .frame(height: 24)
                            TextField("Max", text: $maxMagnificationText)
                                .keyboardType(.decimalPad)
                        }
                    }

                    if showsFocalPlane {
                        Picker("Focal plane", selection: $selectedFocalPlane) {
                            Text("Select").tag(nil as OpticFocalPlane?)
                            ForEach(OpticFocalPlane.allCases) { focalPlane in
                                Text(focalPlane.displayName).tag(Optional(focalPlane))
                            }
                        }
                    }

                    TextField("Reticle (optional)", text: $reticle)
                        .textInputAutocapitalization(.words)
                    Picker("Footprint", selection: $selectedFootprint) {
                        ForEach(OpticFootprint.allCases) { footprint in
                            Text(footprint.displayName).tag(footprint)
                        }
                    }
                    if selectedFootprint == .other {
                        TextField("Footprint details", text: $customFootprint)
                            .textInputAutocapitalization(.words)
                    }
                    TextField("Tube size in mm (optional)", text: $tubeSizeText)
                        .keyboardType(.decimalPad)
                    Toggle("Illuminated", isOn: $isIlluminated)

                    Picker("Color", selection: $selectedColor) {
                        Text("None").tag(nil as FirearmColor?)
                        ForEach(FirearmColor.allCases) { color in
                            Text(color.displayName).tag(Optional(color))
                        }
                    }

                    if selectedColor == .other {
                        TextField("Color details", text: $customColor)
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
            .navigationTitle(optic == nil ? "New Optic" : "Optic Details")
            .navigationBarTitleDisplayMode(.inline)
            .task {
                reloadExistingOptics()
            }
            .onChange(of: serialNumber) {
                guard isEditing else {
                    return
                }
                let normalizedValue = viewModel.normalizedSerialNumber(serialNumber)
                if normalizedValue != serialNumber {
                    serialNumber = normalizedValue
                }
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
        }
    }

    private var resolvedMagnification: (min: Double, max: Double)? {
        viewModel.resolvedMagnification(
            isFixed: isFixedMagnification,
            fixedText: fixedMagnificationText,
            minText: minMagnificationText,
            maxText: maxMagnificationText
        )
    }

    private var resolvedColorDetail: String? {
        viewModel.resolvedColorDetail(selectedColor: selectedColor, customColor: customColor)
    }

    private var resolvedFootprintDetail: String? {
        viewModel.resolvedFootprintDetail(selectedFootprint: selectedFootprint, customFootprint: customFootprint)
    }

    private var resolvedReticle: String? {
        viewModel.optionalValue(reticle)
    }

    private var resolvedNotes: String? {
        viewModel.optionalValue(notes)
    }

    private var resolvedTubeSizeMillimeters: Double? {
        viewModel.tubeSizeMillimeters(from: tubeSizeText)
    }

    private var resolvedFocalPlane: OpticFocalPlane? {
        viewModel.resolvedFocalPlane(
            isFixedMagnification: isFixedMagnification,
            focalPlane: selectedFocalPlane
        )
    }

    private var resolvedPurchasePriceCents: Int? {
        viewModel.purchasePriceCents(from: purchasePriceText)
    }

    private var linkedFirearm: Firearm? {
        viewModel.linkedFirearm(for: optic, unlinkFirearm: unlinkFirearm)
    }

    private var duplicateExists: Bool {
        viewModel.duplicateExists(serialNumber: serialNumber, excluding: optic, in: existingOptics)
    }

    private var showsFocalPlane: Bool {
        viewModel.showsFocalPlane(isFixedMagnification: isFixedMagnification)
    }

    private var purchasePriceWithTaxText: String {
        viewModel.purchasePriceWithTaxText(
            purchasePriceCents: resolvedPurchasePriceCents,
            taxRate: accessoriesTaxRate
        )
    }

    private var isReadOnly: Bool {
        viewModel.isReadOnly(hasOptic: optic != nil, isEditing: isEditing)
    }

    private var showsPurchaseSection: Bool {
        viewModel.showsPurchaseSection(showValueInDetails: showValueInDetails, isReadOnly: isReadOnly)
    }

    private var primaryButtonTitle: String {
        viewModel.primaryButtonTitle(hasOptic: optic != nil, isEditing: isEditing)
    }

    private var canAdd: Bool {
        viewModel.canAdd(
            brand: brand,
            modelName: modelName,
            purchasePriceText: purchasePriceText,
            tubeSizeText: tubeSizeText,
            selectedType: selectedType,
            selectedFootprint: selectedFootprint,
            footprintDetail: resolvedFootprintDetail,
            isFixedMagnification: isFixedMagnification,
            fixedMagnificationText: fixedMagnificationText,
            minMagnificationText: minMagnificationText,
            maxMagnificationText: maxMagnificationText,
            focalPlane: selectedFocalPlane,
            selectedColor: selectedColor,
            colorDetail: resolvedColorDetail,
            duplicateExists: duplicateExists
        )
    }

    private func saveOptic() {
        guard let magnification = resolvedMagnification,
              let purchasePriceCents = resolvedPurchasePriceCents else {
            return
        }

        let didSave: Bool
        if let optic {
            didSave = viewModel.updateOptic(
                optic,
                brand: brand,
                modelName: modelName,
                type: selectedType,
                serialNumber: serialNumber,
                minMagnification: magnification.min,
                maxMagnification: magnification.max,
                footprint: selectedFootprint,
                footprintDetail: resolvedFootprintDetail,
                tubeSizeMillimeters: resolvedTubeSizeMillimeters,
                reticle: resolvedReticle,
                focalPlane: resolvedFocalPlane,
                isIlluminated: isIlluminated,
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
            didSave = viewModel.addOptic(
                brand: brand,
                modelName: modelName,
                type: selectedType,
                serialNumber: serialNumber,
                minMagnification: magnification.min,
                maxMagnification: magnification.max,
                footprint: selectedFootprint,
                footprintDetail: resolvedFootprintDetail,
                tubeSizeMillimeters: resolvedTubeSizeMillimeters,
                reticle: resolvedReticle,
                focalPlane: resolvedFocalPlane,
                isIlluminated: isIlluminated,
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
        if optic == nil {
            dismiss()
        } else {
            isEditing = false
        }
    }

    private func handlePrimaryAction() {
        if optic != nil && !isEditing {
            isEditing = true
            return
        }
        saveOptic()
    }

    private func reloadExistingOptics() {
        do {
            existingOptics = try opticLookupService.fetchExistingOptics(in: context)
        } catch {
            print("Optics fetch error: \(error)")
        }
    }
}
