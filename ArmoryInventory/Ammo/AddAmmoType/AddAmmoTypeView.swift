//
//  AddAmmoTypeView.swift
//  Armory Inventory
//
//  Created by Yinxue Li on 4/2/26.
//

import SwiftUI
import SwiftData

struct AddAmmoTypeView: View {
    private static let customBrandOption = "__custom_brand__"
    private static let customBulletTypeOption = "__custom_bullet_type__"

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    @Bindable var caliber: Caliber

    @State private var selectedBrand: String = CommonAmmoCatalog.commonBrands.first ?? Self.customBrandOption
    @State private var customBrand: String = ""
    @State private var productName = ""
    @State private var selectedBulletType: String = Self.customBulletTypeOption
    @State private var customBulletType: String = ""
    @State private var selectedGrain: Double = 0
    @State private var loadDetailText: String = ""
    @State private var quantityText: String = ""
    @State private var centsPerRoundText: String = ""
    let viewModel: AddAmmoTypeViewModel

    init(caliber: Caliber, viewModel: AddAmmoTypeViewModel) {
        self.caliber = caliber
        self.viewModel = viewModel
        let initialGrain = Double(AddAmmoTypeViewModel.initialGrain(for: caliber))
        let initialBulletType = CommonAmmoCatalog.bulletTypes(for: caliber.name).first ?? Self.customBulletTypeOption
        _selectedGrain = State(initialValue: initialGrain)
        _selectedBulletType = State(initialValue: initialBulletType)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Brand") {
                    Picker("Brand", selection: $selectedBrand) {
                        ForEach(CommonAmmoCatalog.commonBrands, id: \.self) { brand in
                            Text(brand).tag(brand)
                        }
                        Text("Custom").tag(Self.customBrandOption)
                    }
                    if isCustomBrand {
                        TextField("Brand", text: $customBrand)
                            .textInputAutocapitalization(.words)
                    }
                    TextField("Product name (optional)", text: $productName)
                        .textInputAutocapitalization(.words)
                }
                Section("Bullet Type") {
                    Picker("Type", selection: $selectedBulletType) {
                        ForEach(bulletTypes, id: \.self) { bulletType in
                            Text(bulletType).tag(bulletType)
                        }
                        Text("Custom").tag(Self.customBulletTypeOption)
                    }
                    if isCustomBulletType {
                        TextField("Bullet type", text: $customBulletType)
                            .textInputAutocapitalization(.words)
                    }
                }
                Section(loadDetailTitle) {
                    if isShotgun {
                        TextField(loadDetailPlaceholder, text: $loadDetailText)
                    } else if let grainRange {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Weight")
                                Spacer()
                                Text("\(selectedGrainValue)gr")
                                    .foregroundStyle(.secondary)
                            }
                            Slider(
                                value: $selectedGrain,
                                in: Double(grainRange.lowerBound)...Double(grainRange.upperBound),
                                step: 1
                            )
                            HStack {
                                Text("\(grainRange.lowerBound)gr")
                                Spacer()
                                Text("\(grainRange.upperBound)gr")
                            }
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            if let typicalGrainRange {
                                HStack {
                                    Text("Typical: \(typicalGrainRange.lowerBound)gr-\(typicalGrainRange.upperBound)gr")
                                    Spacer()
                                }
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                            }
                        }
                    } else {
                        Text("No common grain options are available for \(caliber.name). Enter a custom weight below.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                        TextField("Grain", text: $loadDetailText)
                            .keyboardType(.numberPad)
                    }
                }
                Section("Starting Quantity") {
                    TextField("Rounds", text: $quantityText)
                        .keyboardType(.numberPad)
                }
                Section("Price") {
                    TextField("Cents per round", text: $centsPerRoundText)
                        .keyboardType(.numberPad)
                }
            }
            .navigationTitle("New Ammo Type")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") { addAmmo() }
                        .disabled(!canAdd)
                }
            }
        }
    }

    private var grainRange: ClosedRange<Int>? {
        viewModel.grainRange(for: caliber)
    }

    private var bulletTypes: [String] {
        viewModel.bulletTypes(for: caliber)
    }

    private var isShotgun: Bool {
        viewModel.isShotgunCaliber(caliber)
    }

    private var typicalGrainRange: ClosedRange<Int>? {
        viewModel.typicalGrainRange(for: caliber)
    }

    private var loadDetailTitle: String {
        viewModel.loadDetailTitle(for: caliber, bulletType: resolvedBulletType)
    }

    private var loadDetailPlaceholder: String {
        viewModel.loadDetailPlaceholder(for: caliber, bulletType: resolvedBulletType)
    }

    private var isCustomBrand: Bool {
        selectedBrand == Self.customBrandOption
    }

    private var isCustomBulletType: Bool {
        selectedBulletType == Self.customBulletTypeOption
    }

    private var selectedGrainValue: Int {
        Int(selectedGrain.rounded())
    }

    private var resolvedBrand: String {
        viewModel.resolvedBrand(
            selectedBrand: selectedBrand,
            customBrand: customBrand,
            isCustomBrand: isCustomBrand
        )
    }

    private var resolvedBulletType: String {
        viewModel.resolvedBulletType(
            selectedBulletType: selectedBulletType,
            customBulletType: customBulletType,
            isCustomBulletType: isCustomBulletType
        )
    }

    private var resolvedProductName: String? {
        viewModel.resolvedProductName(productName)
    }

    private var resolvedGrain: Int? {
        viewModel.resolvedGrain(
            grainRange: grainRange,
            selectedGrainValue: selectedGrainValue,
            customGrainText: loadDetailText
        )
    }

    private var resolvedLoadDetail: String? {
        viewModel.resolvedLoadDetail(
            for: caliber,
            bulletType: resolvedBulletType,
            loadDetailText: loadDetailText
        )
    }

    private var canAdd: Bool {
        viewModel.canAdd(
            quantityText: quantityText,
            centsPerRoundText: centsPerRoundText,
            resolvedBrand: resolvedBrand,
            resolvedBulletType: resolvedBulletType,
            resolvedGrain: resolvedGrain,
            resolvedLoadDetail: resolvedLoadDetail,
            isShotgun: isShotgun
        )
    }

    private func addAmmo() {
        guard viewModel.addAmmo(
            caliber: caliber,
            resolvedBrand: resolvedBrand,
            resolvedProductName: resolvedProductName,
            resolvedBulletType: resolvedBulletType,
            resolvedGrain: resolvedGrain,
            resolvedLoadDetail: resolvedLoadDetail,
            quantityText: quantityText,
            centsPerRoundText: centsPerRoundText,
            to: context
        ) else {
            return
        }
        dismiss()
    }
}
