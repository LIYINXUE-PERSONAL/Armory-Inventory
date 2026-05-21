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
    @State private var selectedKind: KitKind?
    @State private var searchText = ""
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
                        filtersCard

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

                        if showTotalValue {
                            LabeledContent("Total Value", value: totalValueText)
                                .padding(16)
                                .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                        }
                    }
                    .padding()
                }
                .searchable(text: $searchText)
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

    @ViewBuilder
    private var filtersCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    showingFilters.toggle()
                }
            } label: {
                HStack {
                    Text("Filters")
                    Spacer()
                    Image(systemName: "chevron.down")
                        .rotationEffect(.degrees(showingFilters ? 180 : 0))
                        .animation(.easeInOut(duration: 0.2), value: showingFilters)
                        .foregroundStyle(.secondary)
                }
            }
            .buttonStyle(.plain)

            if showingFilters {
                filterControls
                    .transition(.modifier(
                        active: TopAnchoredStretchModifier(progress: 0.01),
                        identity: TopAnchoredStretchModifier(progress: 1)
                    ))
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .animation(.easeInOut(duration: 0.2), value: showingFilters)
    }

    private var filterControls: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                filterMenu(
                    selectionTitle: selectedKind?.displayName ?? String(localized: "All Kinds"),
                    isActive: selectedKind != nil
                ) {
                    Button(allKindsCountText) {
                        selectedKind = nil
                    }

                    ForEach(KitKind.allCases) { kind in
                        Button(viewModel.filterCountText(title: kind.displayName, count: viewModel.countForKind(kind, in: kits))) {
                            selectedKind = kind
                        }
                    }
                }

                if selectedKind != nil {
                    Button("Clear Filters") {
                        selectedKind = nil
                    }
                    .font(.subheadline.weight(.semibold))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(Color(.tertiarySystemFill), in: Capsule())
                }
            }
        }
    }

    private var filteredKits: [Kit] {
        viewModel.filteredKits(kits, selectedKind: selectedKind, searchText: searchText)
    }

    private var totalValueText: String {
        viewModel.totalValueText(for: filteredKits)
    }

    private var allKindsCountText: String {
        viewModel.allKindsCountText(for: kits)
    }

    @ViewBuilder
    private func filterMenu<Content: View>(
        selectionTitle: String,
        isActive: Bool,
        @ViewBuilder content: () -> Content
    ) -> some View {
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
            selectedKind: selectedKind,
            searchText: searchText,
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

private struct TopAnchoredStretchModifier: ViewModifier {
    let progress: CGFloat

    func body(content: Content) -> some View {
        content
            .scaleEffect(x: 1, y: progress, anchor: .top)
            .opacity(progress)
            .clipped()
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
