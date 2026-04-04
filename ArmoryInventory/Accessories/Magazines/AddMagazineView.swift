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
    @State private var selectedCaliber: Caliber?
    @State private var selectedColor: FirearmColor?
    @State private var customColor = ""
    @State private var purchaseDate = Date.now
    @State private var purchasePriceText = "0.00"
    @State private var notes = ""
    @State private var unlinkFirearm = false
    @State private var isEditing = false
    @State private var calibers: [Caliber] = []

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
        _selectedCaliber = State(initialValue: magazine?.caliber)
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
                    TextField("Brand", text: $brand)
                        .textInputAutocapitalization(.words)
                    TextField("Model name", text: $modelName)
                        .textInputAutocapitalization(.words)
                    HStack {
                        Text("Count")
                        TextField("1", text: $countText)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                    }
                }
                .disabled(isReadOnly)

                Section("Configuration") {
                    Picker("Caliber", selection: $selectedCaliber) {
                        Text("None").tag(nil as Caliber?)
                        ForEach(calibers) { caliber in
                            Text(caliber.name).tag(Optional(caliber))
                        }
                    }

                    TextField("Capacity", text: $capacityText)
                        .keyboardType(.numberPad)

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
            .navigationTitle(magazine == nil ? "New Magazine" : "Magazine Details")
            .navigationBarTitleDisplayMode(.inline)
            .task {
                reloadCalibers()
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

    private var resolvedColorDetail: String? {
        viewModel.resolvedColorDetail(selectedColor: selectedColor, customColor: customColor)
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
            purchasePriceText: purchasePriceText
        )
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
                caliber: selectedCaliber,
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
                caliber: selectedCaliber,
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

    private func reloadCalibers() {
        do {
            calibers = try caliberQueryService.fetchCalibers(in: context)
        } catch {
            print("Calibers fetch error: \(error)")
        }
    }
}
