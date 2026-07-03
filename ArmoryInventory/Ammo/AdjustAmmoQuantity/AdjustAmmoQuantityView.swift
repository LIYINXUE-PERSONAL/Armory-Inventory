//
//  AdjustAmmoQuantityView.swift
//  Armory Inventory
//
//  Created by Yinxue Li on 4/2/26.
//

import SwiftUI

struct AdjustAmmoQuantityView: View {
    private enum AdjustmentMode: String, CaseIterable, Identifiable {
        case add = "+"
        case remove = "-"

        var id: String { rawValue }

        var multiplier: Int {
            switch self {
            case .add:
                return 1
            case .remove:
                return -1
            }
        }
    }

    @Environment(\.dismiss) private var dismiss

    let ammo: AmmoType
    let viewModel: AdjustAmmoQuantityViewModel
    let onApply: (Int, Date) -> Void
    let onDelete: () -> Void

    @State private var showingEditAmmo = false
    @State private var adjustmentMode: AdjustmentMode = .add
    @State private var quantityDeltaText: String = ""
    @State private var changeDate = Date()

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Form {
                    Section("Ammo") {
                        LabeledContent("Product", value: "\(ammo.brand) \(ammo.productName?.isEmpty ?? true ? "" : "\(ammo.productName!) ")\(ammo.loadDescription)")
                        LabeledContent("Current", value: AmmoType.roundsText(for: ammo.quantity))
                    }

                    Section("Adjust Quantity") {
                        HStack(spacing: 4) {
                            Picker("Mode", selection: $adjustmentMode) {
                                ForEach(AdjustmentMode.allCases) { mode in
                                    Text(mode.rawValue).tag(mode)
                                }
                            }
                            .pickerStyle(.palette)
                            .frame(width: 72)

                            TextField("Rounds", text: $quantityDeltaText)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.trailing)
                        }

                        DatePicker("Date", selection: $changeDate, displayedComponents: .date)
                    }
                    
                    Button("Apply") {
                        applyChange()
                    }
                    .buttonStyle(.borderless)
                    .font(.headline)
                    .disabled(
                        !viewModel.canApply(
                            quantityDeltaText: quantityDeltaText,
                            currentQuantity: ammo.quantity,
                            multiplier: adjustmentMode.multiplier
                        )
                    )
                    .frame(maxWidth: .infinity, alignment: .center)
                }
            }
            .navigationTitle("Adjust Quantity")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
                ToolbarItemGroup(placement: .primaryAction) {
                    Button("Edit") {
                        showingEditAmmo = true
                    }

                    Button("Delete", role: .destructive) {
                        onDelete()
                    }
                    .tint(.red)
                }
            }
            .sheet(isPresented: $showingEditAmmo) {
                if let caliber = ammo.caliber {
                    AddAmmoTypeView(
                        caliber: caliber,
                        ammoToEdit: ammo,
                        viewModel: AddAmmoTypeViewModel()
                    )
                    .presentationDetents([.large])
                }
            }
        }
    }

    private func applyChange() {
        guard let delta = viewModel.deltaToApply(
            quantityDeltaText: quantityDeltaText,
            currentQuantity: ammo.quantity,
            multiplier: adjustmentMode.multiplier
        ) else {
            return
        }
        onApply(delta, changeDate)
        dismiss()
    }
}
