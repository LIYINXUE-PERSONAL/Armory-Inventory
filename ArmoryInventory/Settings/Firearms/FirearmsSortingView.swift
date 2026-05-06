//
//  FirearmSettingsView.swift
//  Armory Inventory
//
//  Created by Codex on 4/2/26.
//

import SwiftUI

enum FirearmSortOrder: String, CaseIterable, Identifiable {
    case manual
    case purchaseDate
    case value
    case barrelLength
    case brand
    case caliber
    case type

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .manual:
            return String(localized: "Manual")
        case .purchaseDate:
            return String(localized: "Purchase Date")
        case .value:
            return String(localized: "Value")
        case .barrelLength:
            return String(localized: "Barrel Length")
        case .brand:
            return String(localized: "Brand")
        case .caliber:
            return String(localized: "Caliber")
        case .type:
            return String(localized: "Type")
        }
    }
}

enum FirearmSortDirection: String, CaseIterable, Identifiable {
    case ascending
    case descending

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .ascending:
            return String(localized: "Ascending")
        case .descending:
            return String(localized: "Descending")
        }
    }
}

struct FirearmsSortingView: View {
    @AppStorage(InventorySettingsKeys.firearmSortOrder) private var firearmSortOrder = FirearmSortOrder.manual.rawValue
    @AppStorage(InventorySettingsKeys.firearmSortDirection) private var firearmSortDirectionRaw = ""

    var body: some View {
        List {
            Section("Ordering") {
                Picker("Sort Firearms By", selection: $firearmSortOrder) {
                    ForEach(FirearmSortOrder.allCases) { sortOrder in
                        Text(sortOrder.displayName).tag(sortOrder.rawValue)
                    }
                }

                if selectedSortOrder != .manual {
                    Picker("Direction", selection: sortDirectionBinding) {
                        ForEach(FirearmSortDirection.allCases) { direction in
                            Text(direction.displayName).tag(direction)
                        }
                    }
                    .pickerStyle(.segmented)
                }
            }
        }
        .navigationTitle("Firearms Sorting")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var selectedSortOrder: FirearmSortOrder {
        FirearmSortOrder(rawValue: firearmSortOrder) ?? .manual
    }

    private var sortDirectionBinding: Binding<FirearmSortDirection> {
        Binding(
            get: {
                FirearmSortDirection(rawValue: firearmSortDirectionRaw) ?? preferredDirection(for: selectedSortOrder)
            },
            set: { direction in
                firearmSortDirectionRaw = direction.rawValue
            }
        )
    }

    private func preferredDirection(for sortOrder: FirearmSortOrder) -> FirearmSortDirection {
        switch sortOrder {
        case .manual:
            return .ascending
        case .purchaseDate, .value, .barrelLength:
            return .descending
        case .brand, .caliber, .type:
            return .ascending
        }
    }
}
