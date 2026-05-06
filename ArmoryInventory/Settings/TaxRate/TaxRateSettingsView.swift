//
//  TaxRateSettingsView.swift
//  Armory Inventory
//
//  Created by Codex on 4/2/26.
//

import SwiftUI

struct TaxRateSettingsView: View {
    @AppStorage(InventorySettingsKeys.firearmsSalesTaxRate) private var firearmsTaxRate = 0.0
    @AppStorage(InventorySettingsKeys.ammoSalesTaxRate) private var ammoTaxRate = 0.0
    @AppStorage(InventorySettingsKeys.accessoriesSalesTaxRate) private var accessoriesTaxRate = 0.0
    @State private var firearmsTaxRateText = ""
    @State private var ammoTaxRateText = ""
    @State private var accessoriesTaxRateText = ""
    private let sliderUpperBound = 100.0

    var body: some View {
        Form {
            Section {
                Text(String(localized: "Use the slider to set a rate from 0% to 100%. Move it all the way to 100% to unlock a custom value above that range."))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            taxRateSection(category: .firearms, storedRate: $firearmsTaxRate, customText: $firearmsTaxRateText)
            taxRateSection(category: .ammo, storedRate: $ammoTaxRate, customText: $ammoTaxRateText)
            taxRateSection(category: .accessories, storedRate: $accessoriesTaxRate, customText: $accessoriesTaxRateText)
        }
        .navigationTitle(String(localized: "Tax Rate"))
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            firearmsTaxRateText = formattedTaxRate(firearmsTaxRate)
            ammoTaxRateText = formattedTaxRate(ammoTaxRate)
            accessoriesTaxRateText = formattedTaxRate(accessoriesTaxRate)
        }
    }

    @ViewBuilder
    private func taxRateSection(category: InventoryTaxCategory, storedRate: Binding<Double>, customText: Binding<String>) -> some View {
        Section(category.title) {
            Slider(
                value: Binding(
                    get: { min(max(storedRate.wrappedValue, 0), sliderUpperBound) },
                    set: { newValue in
                        let clampedValue = min(max(newValue, 0), sliderUpperBound)
                        if storedRate.wrappedValue <= sliderUpperBound || clampedValue < sliderUpperBound {
                            storedRate.wrappedValue = clampedValue
                            if clampedValue < sliderUpperBound {
                                customText.wrappedValue = formattedTaxRate(clampedValue)
                            }
                        } else {
                            storedRate.wrappedValue = max(storedRate.wrappedValue, sliderUpperBound)
                        }
                    }
                ),
                in: 0...sliderUpperBound,
                step: 0.1
            )
            HStack {
                Text(String(localized: "0%"))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(String(localized: "100%+"))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            Text(
                String.localizedStringWithFormat(
                    String(localized: "Current: %@%%"),
                    formattedTaxRate(storedRate.wrappedValue)
                )
            )
                .font(.footnote)
                .foregroundStyle(.secondary)

            if storedRate.wrappedValue >= sliderUpperBound {
                HStack(spacing: 12) {
                    TextField(String(localized: "Custom percent"), text: customText)
                        .keyboardType(.decimalPad)
                        .onAppear {
                            customText.wrappedValue = formattedTaxRate(storedRate.wrappedValue)
                        }

                    Button(String(localized: "Update")) {
                        updateTaxRate(from: customText, storedRate: storedRate)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                    .disabled(!isValidTaxRateInput(customText.wrappedValue))
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
    }

    private func isValidTaxRateInput(_ text: String) -> Bool {
        guard let value = Double(text) else {
            return false
        }
        return value >= 0
    }

    private func formattedTaxRate(_ value: Double) -> String {
        if value.rounded() == value {
            return String(Int(value))
        }
        return String(value)
    }

    private func updateTaxRate(from customText: Binding<String>, storedRate: Binding<Double>) {
        guard let value = Double(customText.wrappedValue), value >= 0 else {
            if customText.wrappedValue.isEmpty {
                storedRate.wrappedValue = sliderUpperBound
                customText.wrappedValue = formattedTaxRate(storedRate.wrappedValue)
            }
            return
        }
        storedRate.wrappedValue = value
        if value >= sliderUpperBound {
            customText.wrappedValue = formattedTaxRate(value)
        }
    }
}
