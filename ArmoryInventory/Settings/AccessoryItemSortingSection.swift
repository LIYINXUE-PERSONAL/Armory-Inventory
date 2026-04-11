//
//  AccessoryItemSortingSection.swift
//  Armory Inventory
//
//  Created by Codex on 4/6/26.
//

import SwiftUI

struct AccessoryItemSortingSection: View {
    @Binding var sortOrderRaw: String
    @Binding var sortDirectionRaw: String
    let itemLabelPlural: String

    var body: some View {
        Section("Ordering") {
            Picker("Sort \(itemLabelPlural) In Each Type By", selection: $sortOrderRaw) {
                ForEach(AccessoryItemSortOrder.allCases) { sortOrder in
                    Text(sortOrder.displayName).tag(sortOrder.rawValue)
                }
            }

            if selectedSortOrder != .manual {
                Picker("Direction", selection: sortDirectionBinding) {
                    ForEach(AccessoryItemSortDirection.allCases) { direction in
                        Text(direction.displayName).tag(direction)
                    }
                }
                .pickerStyle(.segmented)
            }
        }
    }

    private var selectedSortOrder: AccessoryItemSortOrder {
        AccessoryItemSortOrder(rawValue: sortOrderRaw) ?? .manual
    }

    private var sortDirectionBinding: Binding<AccessoryItemSortDirection> {
        Binding(
            get: {
                AccessoryItemSortDirection(rawValue: sortDirectionRaw) ?? AccessoryItemSort.preferredDirection(for: selectedSortOrder)
            },
            set: { direction in
                sortDirectionRaw = direction.rawValue
            }
        )
    }
}
