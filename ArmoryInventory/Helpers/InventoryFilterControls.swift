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
        VStack(alignment: .leading, spacing: 12) {
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

            if isExpanded {
                content()
                    .transition(.modifier(
                        active: TopAnchoredStretchModifier(progress: 0.01),
                        identity: TopAnchoredStretchModifier(progress: 1)
                    ))
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
    @Binding var selectedStatusFilter: AccessoryLinkStatusFilter

    var body: some View {
        InventoryFiltersCard(isExpanded: $isExpanded) {
            InventoryFilterControls {
                AccessoryLinkStatusFilterMenu(selectedStatusFilter: $selectedStatusFilter)

                if selectedStatusFilter != .all {
                    InventoryClearFiltersButton {
                        selectedStatusFilter = .all
                    }
                }
            }
        }
    }
}

private struct TopAnchoredStretchModifier: ViewModifier {
    let progress: CGFloat

    func body(content: Content) -> some View {
        content
            .scaleEffect(x: 1, y: progress, anchor: .top)
            .opacity(progress)
            .clipped()
    }
}
