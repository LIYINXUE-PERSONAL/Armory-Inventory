//
//  KitsView.swift
//  Armory Inventory
//
//  Created by Codex on 5/14/26.
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct KitsView: View {
    @Environment(\.modelContext) private var context
    @AppStorage(InventorySettingsKeys.showValueInCard) private var showValueInCard = true
    @AppStorage(InventorySettingsKeys.showTotalValue) private var showTotalValue = true
    @State private var showingAddKit = false
    @State private var selectedKit: Kit?
    @State private var showingFilters = false
    @State private var selectedKinds: Set<KitKind> = []
    @State private var selectedStatusFilters: Set<AccessoryLinkStatusFilter> = []
    @State private var kits: [Kit] = []
    @State private var alertMessage: String?
    @State private var showsExpandedCards = false
    @State private var draggedKit: Kit?

    private let viewModel = KitsViewModel()
    private let inventoryListService: InventoryListServicing = AppServices.shared.resolve(InventoryListServicing.self)

    var body: some View {
        Group {
            if kits.isEmpty {
                ContentUnavailableView(
                    "No Kits Yet",
                    systemImage: "shippingbox.fill",
                    description: Text("Build kits from unlinked parts, optics, and attachments.")
                )
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 16) {
                        if filteredKits.isEmpty {
                            ContentUnavailableView(
                                "No Matching Kits",
                                systemImage: "line.3.horizontal.decrease.circle",
                                description: Text("No kits match the selected filters.")
                            )
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 32)
                        } else {
                            ForEach(filteredKits) { kit in
                                Button {
                                    selectedKit = kit
                                } label: {
                                    KitCardView(
                                        kit: kit,
                                        componentSummaries: viewModel.componentSummaries(for: kit),
                                        showsExpandedCards: showsExpandedCards,
                                        showValueInCard: showValueInCard
                                    )
                                }
                                .buttonStyle(.plain)
                                .onDrag {
                                    draggedKit = kit
                                    return NSItemProvider(object: kit.displayName as NSString)
                                }
                                .onDrop(
                                    of: [UTType.text],
                                    delegate: KitDropDelegate(
                                        targetKit: kit,
                                        kits: filteredKits,
                                        draggedKit: $draggedKit,
                                        onMove: moveKits
                                    )
                                )
                            }
                        }

                        if showTotalValue {
                            LabeledContent("Total Value", value: totalValueText)
                                .padding(16)
                                .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationTitle("Kits")
        .task {
            reloadKits()
        }
        .onAppear {
            reloadKits()
        }
        .onChange(of: showingAddKit) {
            if !showingAddKit {
                reloadKits()
            }
        }
        .onChange(of: selectedKit) {
            if selectedKit == nil {
                reloadKits()
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                InventoryFilterToolbarButton(activeFilterCount: activeFilterCount) {
                    showingFilters = true
                }

                Button {
                    withAnimation(.snappy(duration: 0.24, extraBounce: 0)) {
                        showsExpandedCards.toggle()
                    }
                } label: {
                    Image(systemName: showsExpandedCards ? "rectangle.compress.vertical" : "rectangle.expand.vertical")
                }

                Button {
                    showingAddKit = true
                } label: {
                    Label("Add Kit", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddKit) {
            AddKitView(viewModel: AddKitViewModel())
                .presentationDetents([.large])
        }
        .sheet(isPresented: $showingFilters) {
            InventoryFiltersSheet(hasActiveFilters: hasActiveFilters, clearFilters: clearFilters) {
                InventoryMultiSelectFilterSection(
                    title: String(localized: "Kind"),
                    options: kindFilterOptions,
                    selection: $selectedKinds
                )

                InventoryMultiSelectFilterSection(
                    title: String(localized: "Status"),
                    options: statusFilterOptions,
                    selection: $selectedStatusFilters
                )
            }
        }
        .sheet(item: $selectedKit) { kit in
            AddKitView(kit: kit, viewModel: AddKitViewModel())
                .presentationDetents([.large])
        }
        .alert("Kit Action Failed", isPresented: alertBinding) {
            Button("OK", role: .cancel) {
                alertMessage = nil
            }
        } message: {
            Text(alertMessage ?? "")
        }
    }

    private var filteredKits: [Kit] {
        viewModel.filteredKits(
            kits,
            selectedKinds: selectedKinds,
            selectedStatusFilters: selectedStatusFilters
        )
    }

    private var totalValueText: String {
        viewModel.totalValueText(for: filteredKits)
    }

    private var kindFilterOptions: [InventoryFilterOption<KitKind>] {
        KitKind.allCases.map {
            InventoryFilterOption(id: $0, title: $0.displayName, count: viewModel.countForKind($0, in: kits))
        }
    }

    private var statusFilterOptions: [InventoryFilterOption<AccessoryLinkStatusFilter>] {
        [
            InventoryFilterOption(id: .linked, title: AccessoryLinkStatusFilter.linked.displayName, count: kits.count { $0.firearm != nil }),
            InventoryFilterOption(id: .unlinked, title: AccessoryLinkStatusFilter.unlinked.displayName, count: kits.count { $0.firearm == nil })
        ]
    }

    private var activeFilterCount: Int {
        selectedKinds.count + selectedStatusFilters.count
    }

    private var hasActiveFilters: Bool {
        activeFilterCount > 0
    }

    private func clearFilters() {
        selectedKinds.removeAll()
        selectedStatusFilters.removeAll()
    }

    private var alertBinding: Binding<Bool> {
        Binding(
            get: { alertMessage != nil },
            set: { if !$0 { alertMessage = nil } }
        )
    }

    private func moveKits(from source: IndexSet, to destination: Int) {
        let result = viewModel.moveKits(
            allKits: kits,
            filteredKits: filteredKits,
            selectedKinds: selectedKinds,
            selectedStatusFilters: selectedStatusFilters,
            source: source,
            destination: destination,
            in: context
        )
        if result.isValid {
            reloadKits()
        } else {
            alertMessage = result.message
        }
    }

    private func reloadKits() {
        do {
            kits = try inventoryListService.fetchKits(in: context)
        } catch {
            print("Kits fetch error: \(error)")
        }
    }
}

private struct KitCardView: View {
    let kit: Kit
    let componentSummaries: [KitComponentSummary]
    let showsExpandedCards: Bool
    let showValueInCard: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(kit.displayName)
                        .font(.headline)
                    Text(kit.kitKind.displayName)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }

            LabeledContent("Components", value: kit.componentCountText)

            if let firearm = kit.firearm {
                LabeledContent("Linked Firearm", value: firearm.displayName)
            }

            AnimatedExpandableSection(isExpanded: showsExpandedCards) {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(componentSummaries) { summary in
                        VStack(alignment: .leading, spacing: 2) {
                            Text(summary.title)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                            Text(summary.itemNames)
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                                .lineLimit(2)
                        }
                    }

                    if showValueInCard, kit.totalValueCents > 0 {
                        LabeledContent("Value", value: kit.totalValueText)
                    }
                }
            }
        }
        .padding(16)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .contentShape(Rectangle())
    }

}

private struct KitDropDelegate: DropDelegate {
    let targetKit: Kit
    let kits: [Kit]
    @Binding var draggedKit: Kit?
    let onMove: (IndexSet, Int) -> Void

    func dropEntered(info: DropInfo) {
        guard let draggedKit else {
            return
        }
        guard draggedKit.persistentModelID != targetKit.persistentModelID else {
            return
        }
        guard
            let fromIndex = kits.firstIndex(where: { $0.persistentModelID == draggedKit.persistentModelID }),
            let toIndex = kits.firstIndex(where: { $0.persistentModelID == targetKit.persistentModelID })
        else {
            return
        }

        withAnimation(.snappy(duration: 0.2, extraBounce: 0)) {
            onMove(IndexSet(integer: fromIndex), toIndex > fromIndex ? toIndex + 1 : toIndex)
        }
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        DropProposal(operation: .move)
    }

    func performDrop(info: DropInfo) -> Bool {
        draggedKit = nil
        return true
    }
}

private struct AnimatedExpandableSection<Content: View>: View {
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
            .frame(maxHeight: isExpanded ? max(contentHeight, 1) : 0, alignment: .top)
            .clipped()
            .opacity(isExpanded ? 1 : 0)
            .accessibilityHidden(!isExpanded)
    }
}
