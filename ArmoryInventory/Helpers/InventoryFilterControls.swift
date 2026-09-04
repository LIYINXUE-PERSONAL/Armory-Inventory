//
//  InventoryFilterControls.swift
//  Armory Inventory
//
//  Created by Codex on 9/3/26.
//

import SwiftUI

struct InventoryFilterOption<ID: Hashable>: Identifiable {
    let id: ID
    let title: String
    let count: Int?
}

struct InventoryFilterToolbarButton: View {
    let activeFilterCount: Int
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack(alignment: .topTrailing) {
                Image(systemName: activeFilterCount > 0 ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                    .font(.title3)

                if activeFilterCount > 0 {
                    Text(activeFilterCount.localizedCountString)
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.white)
                        .monospacedDigit()
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(.blue, in: Capsule())
                        .offset(x: 10, y: -8)
                        .accessibilityHidden(true)
                }
            }
        }
        .accessibilityLabel("Filters")
    }
}

struct InventoryFiltersSheet<Content: View>: View {
    let hasActiveFilters: Bool
    let clearFilters: () -> Void
    @ViewBuilder let content: () -> Content

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                content()
            }
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Clear") {
                        clearFilters()
                    }
                    .disabled(!hasActiveFilters)
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

struct InventoryMultiSelectFilterSection<ID: Hashable>: View {
    let title: String
    let options: [InventoryFilterOption<ID>]
    @Binding var selection: Set<ID>

    var body: some View {
        Section {
            ForEach(options) { option in
                Button {
                    toggle(option.id)
                } label: {
                    HStack {
                        Text(option.title)
                            .foregroundStyle(.primary)

                        Spacer()

                        if let count = option.count {
                            Text(count.localizedCountString)
                                .foregroundStyle(.secondary)
                                .monospacedDigit()
                        }

                        if selection.contains(option.id) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.blue)
                                .imageScale(.large)
                        } else {
                            Image(systemName: "circle")
                                .foregroundStyle(.tertiary)
                                .imageScale(.large)
                        }
                    }
                }
            }
        } header: {
            HStack {
                Text(title)
                Spacer()
                if !selection.isEmpty {
                    Text(selectedCountText)
                        .textCase(nil)
                }
            }
        }
    }

    private var selectedCountText: String {
        String.localizedStringWithFormat(
            String(localized: "%@ selected"),
            selection.count.localizedCountString
        )
    }

    private func toggle(_ optionID: ID) {
        if selection.contains(optionID) {
            selection.remove(optionID)
        } else {
            selection.insert(optionID)
        }
    }
}
