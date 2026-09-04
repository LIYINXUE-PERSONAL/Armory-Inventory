//
//  InventoryFilterControls.swift
//  Armory Inventory
//
//  Created by Codex on 9/3/26.
//

import SwiftUI

struct InventoryFiltersCard<Content: View>: View {
    @Binding var isExpanded: Bool
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack {
                    Text("Filters")
                    Spacer()
                    Image(systemName: "chevron.down")
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                        .animation(.easeInOut(duration: 0.2), value: isExpanded)
                        .foregroundStyle(.secondary)
                }
            }
            .buttonStyle(.plain)

            TopAlignedExpandableContent(isExpanded: isExpanded) {
                content()
                    .padding(.top, 12)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .animation(.easeInOut(duration: 0.2), value: isExpanded)
    }
}

struct InventoryFilterControls<Content: View>: View {
    @ViewBuilder let content: () -> Content

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                content()
            }
        }
    }
}

struct InventoryFilterMenu<Content: View>: View {
    let selectionTitle: String
    let isActive: Bool
    @ViewBuilder let content: () -> Content

    var body: some View {
        Menu {
            content()
        } label: {
            HStack(spacing: 8) {
                Text(selectionTitle)
                    .font(.subheadline)
                Image(systemName: "chevron.down")
                    .font(.caption.weight(.semibold))
            }
            .foregroundStyle(isActive ? .primary : .secondary)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(isActive ? Color(.tertiarySystemFill) : Color(.secondarySystemFill), in: Capsule())
        }
        .buttonStyle(.plain)
    }
}

struct InventoryClearFiltersButton: View {
    let action: () -> Void

    var body: some View {
        Button("Clear Filters", action: action)
            .font(.subheadline.weight(.semibold))
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(Color(.tertiarySystemFill), in: Capsule())
    }
}

struct AccessoryLinkStatusFilterMenu: View {
    @Binding var selectedStatusFilter: AccessoryLinkStatusFilter

    var body: some View {
        InventoryFilterMenu(
            selectionTitle: selectedStatusFilter == .all ? String(localized: "All Statuses") : selectedStatusFilter.displayName,
            isActive: selectedStatusFilter != .all
        ) {
            ForEach(AccessoryLinkStatusFilter.allCases) { status in
                Button(status.displayName) {
                    selectedStatusFilter = status
                }
            }
        }
    }
}

struct AccessoryLinkStatusFiltersCard: View {
    @Binding var isExpanded: Bool
    var typeOptions: [InventoryTypeFilterOption] = []
    @Binding var selectedType: String?
    @Binding var selectedStatusFilter: AccessoryLinkStatusFilter

    init(isExpanded: Binding<Bool>, selectedStatusFilter: Binding<AccessoryLinkStatusFilter>) {
        self._isExpanded = isExpanded
        self.typeOptions = []
        self._selectedType = .constant(nil)
        self._selectedStatusFilter = selectedStatusFilter
    }

    init(
        isExpanded: Binding<Bool>,
        typeOptions: [InventoryTypeFilterOption],
        selectedType: Binding<String?>,
        selectedStatusFilter: Binding<AccessoryLinkStatusFilter>
    ) {
        self._isExpanded = isExpanded
        self.typeOptions = typeOptions
        self._selectedType = selectedType
        self._selectedStatusFilter = selectedStatusFilter
    }

    var body: some View {
        InventoryFiltersCard(isExpanded: $isExpanded) {
            InventoryFilterControls {
                if !typeOptions.isEmpty {
                    InventoryTypeFilterMenu(options: typeOptions, selectedType: $selectedType)
                }

                AccessoryLinkStatusFilterMenu(selectedStatusFilter: $selectedStatusFilter)

                if selectedType != nil || selectedStatusFilter != .all {
                    InventoryClearFiltersButton {
                        selectedType = nil
                        selectedStatusFilter = .all
                    }
                }
            }
        }
    }
}

struct InventoryTypeFilterOption: Identifiable, Hashable {
    let id: String
    let displayName: String
}

struct InventoryTypeFilterMenu: View {
    let options: [InventoryTypeFilterOption]
    @Binding var selectedType: String?

    private var selectedTitle: String {
        guard let selectedType,
              let option = options.first(where: { $0.id == selectedType }) else {
            return String(localized: "All Types")
        }
        return option.displayName
    }

    var body: some View {
        InventoryFilterMenu(
            selectionTitle: selectedTitle,
            isActive: selectedType != nil
        ) {
            Button("All Types") {
                selectedType = nil
            }

            ForEach(options) { option in
                Button(option.displayName) {
                    selectedType = option.id
                }
            }
        }
    }
}

private struct TopAlignedExpandableContent<Content: View>: View {
    let isExpanded: Bool
    @ViewBuilder let content: () -> Content

    @State private var contentHeight: CGFloat = .zero

    var body: some View {
        content()
            .fixedSize(horizontal: false, vertical: true)
            .background(
                GeometryReader { proxy in
                    Color.clear
                        .onAppear {
                            contentHeight = proxy.size.height
                        }
                        .onChange(of: proxy.size.height) {
                            contentHeight = proxy.size.height
                        }
                }
            )
            .frame(height: isExpanded ? max(contentHeight, 1) : 0, alignment: .top)
            .clipped()
            .opacity(isExpanded ? 1 : 0)
            .accessibilityHidden(!isExpanded)
    }
}
