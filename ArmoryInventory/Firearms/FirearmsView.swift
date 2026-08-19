//
//  FirearmsView.swift
//  Armory Inventory
//
//  Created by Codex on 4/2/26.
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct FirearmsView: View {
    @Environment(\.modelContext) private var context
    @AppStorage(InventorySettingsKeys.showValueInCard) private var showValueInCard = true
    @AppStorage(InventorySettingsKeys.showTotalValue) private var showTotalValue = true
    @AppStorage(InventorySettingsKeys.firearmSortOrder) private var firearmSortOrder = FirearmSortOrder.manual.rawValue
    @AppStorage(InventorySettingsKeys.firearmSortDirection) private var firearmSortDirectionRaw = ""
    @State private var showingAddFirearm = false
    @State private var selectedFirearm: Firearm?
    @State private var selectedCaliber: Caliber?
    @State private var showingFilters = false
    @State private var selectedTypeFilter: FirearmType?
    @State private var selectedActionFilter: FirearmAction?
    @State private var selectedCaliberFilter: Caliber?
    @State private var firearms: [Firearm] = []
    @State private var kits: [Kit] = []
    @State private var magazines: [Magazine] = []
    @State private var showsExpandedCards = false
    @State private var draggedFirearm: Firearm?

    private let viewModel = FirearmsViewModel()
    private let inventoryListService: InventoryListServicing = AppServices.shared.resolve(InventoryListServicing.self)

    var body: some View {
        NavigationStack {
            Group {
                if firearms.isEmpty {
                    ContentUnavailableView(
                        "No Firearms Yet",
                        systemImage: "shield.lefthalf.filled",
                        description: Text("Add your first firearm to start tracking your collection.")
                    )
                } else {
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 16) {
                            filtersCard

                            ForEach(filteredFirearms) { firearm in
                                FirearmCardView(
                                    firearm: firearm,
                                    configuration: firearm.resolvedConfiguration(kits: kits),
                                    showsExpandedCards: showsExpandedCards,
                                    showValueInCard: showValueInCard,
                                    effectiveValueCents: viewModel.effectiveValueCents(for: firearm, kits: kits, magazines: magazines),
                                    onTap: {
                                        selectedFirearm = firearm
                                    },
                                    onSelectCaliber: {
                                        if let caliber = firearm.resolvedConfiguration(kits: kits).caliber {
                                            selectedCaliber = caliber
                                        }
                                    }
                                )
                                .onDrag {
                                    guard selectedSortOrder == .manual else {
                                        return NSItemProvider()
                                    }
                                    draggedFirearm = firearm
                                    return NSItemProvider(object: firearm.displayName as NSString)
                                }
                                .onDrop(
                                    of: [UTType.text],
                                    delegate: FirearmDropDelegate(
                                        targetFirearm: firearm,
                                        firearms: filteredFirearms,
                                        draggedFirearm: $draggedFirearm,
                                        onMove: moveFirearms
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
                }
            }
            .navigationTitle("Firearms")
            .task {
                reloadFirearms()
            }
            .onAppear {
                reloadFirearms()
            }
            .onChange(of: showingAddFirearm) {
                if !showingAddFirearm {
                    reloadFirearms()
                }
            }
            .onChange(of: selectedFirearm) {
                if selectedFirearm == nil {
                    reloadFirearms()
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
                        showingAddFirearm = true
                    } label: {
                        Label("Add Firearm", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddFirearm) {
                AddFirearmView(viewModel: AddFirearmViewModel())
                    .presentationDetents([.large])
            }
            .sheet(item: $selectedFirearm) { firearm in
                AddFirearmView(firearm: firearm, viewModel: AddFirearmViewModel())
                    .presentationDetents([.large])
            }
            .navigationDestination(item: $selectedCaliber) { caliber in
                CaliberDetailView(caliber: caliber, viewModel: CaliberListViewModel())
            }
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
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        filterMenu(
                            selectionTitle: selectedTypeFilter?.displayName ?? String(localized: "All Types"),
                            isActive: selectedTypeFilter != nil
                        ) {
                            Button(allTypesCountText) {
                                selectedTypeFilter = nil
                            }

                            ForEach(FirearmType.allCases) { firearmType in
                                Button(viewModel.filterCountText(title: firearmType.displayName, count: viewModel.countForType(firearmType, in: firearms))) {
                                    selectedTypeFilter = firearmType
                                }
                            }
                        }

                        filterMenu(
                            selectionTitle: selectedActionFilter?.displayName ?? String(localized: "All Actions"),
                            isActive: selectedActionFilter != nil
                        ) {
                            Button(allActionsCountText) {
                                selectedActionFilter = nil
                            }

                            ForEach(FirearmAction.allCases) { action in
                                Button(viewModel.filterCountText(title: action.displayName, count: viewModel.countForAction(action, in: firearms))) {
                                    selectedActionFilter = action
                                }
                            }
                        }

                        filterMenu(
                            selectionTitle: selectedCaliberFilter?.name ?? String(localized: "All Calibers"),
                            isActive: selectedCaliberFilter != nil
                        ) {
                            Button(allCalibersCountText) {
                                selectedCaliberFilter = nil
                            }

                            ForEach(viewModel.availableCalibers(from: firearms)) { caliber in
                                Button(viewModel.filterCountText(title: caliber.name, count: viewModel.countForCaliber(caliber, in: firearms))) {
                                    selectedCaliberFilter = caliber
                                }
                            }
                        }

                        if selectedTypeFilter != nil || selectedActionFilter != nil || selectedCaliberFilter != nil {
                            Button("Clear Filters") {
                                selectedTypeFilter = nil
                                selectedActionFilter = nil
                                selectedCaliberFilter = nil
                            }
                            .font(.subheadline.weight(.semibold))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(Color(.tertiarySystemFill), in: Capsule())
                        }
                    }
                }
                .transition(.modifier(
                    active: TopAnchoredStretchModifier(progress: 0.01),
                    identity: TopAnchoredStretchModifier(progress: 1)
                ))
            }
        }
        .padding(16)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .animation(.easeInOut(duration: 0.2), value: showingFilters)
    }

    private var filteredFirearms: [Firearm] {
        viewModel.filteredFirearms(
            firearms,
            kits: kits,
            magazines: magazines,
            selectedTypeFilter: selectedTypeFilter,
            selectedActionFilter: selectedActionFilter,
            selectedCaliberFilter: selectedCaliberFilter,
            sortOrder: selectedSortOrder,
            sortDirection: selectedSortDirection
        )
    }

    private func moveFirearms(from source: IndexSet, to destination: Int) {
        let result = viewModel.moveFirearms(
            allFirearms: firearms,
            filteredFirearms: filteredFirearms,
            selectedTypeFilter: selectedTypeFilter,
            selectedActionFilter: selectedActionFilter,
            selectedCaliberFilter: selectedCaliberFilter,
            sortOrder: selectedSortOrder,
            source: source,
            destination: destination,
            in: context
        )
        if result.isValid {
            reloadFirearms()
        } else {
            print("Reorder error: \(result.message ?? "")")
        }
    }

    private func reloadFirearms() {
        do {
            firearms = try inventoryListService.fetchFirearms(in: context)
            kits = try inventoryListService.fetchKits(in: context)
            magazines = try inventoryListService.fetchMagazines(in: context)
        } catch {
            print("Firearms fetch error: \(error)")
        }
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

    private var totalValueText: String {
        viewModel.totalValueText(for: filteredFirearms, kits: kits, magazines: magazines)
    }

    private var allTypesCountText: String {
        viewModel.allTypesCountText(for: firearms)
    }

    private var allActionsCountText: String {
        viewModel.allActionsCountText(for: firearms)
    }

    private var allCalibersCountText: String {
        viewModel.allCalibersCountText(for: firearms)
    }

    private var selectedSortOrder: FirearmSortOrder {
        viewModel.selectedSortOrder(from: firearmSortOrder)
    }

    private var selectedSortDirection: FirearmSortDirection {
        viewModel.selectedSortDirection(from: firearmSortDirectionRaw, sortOrder: selectedSortOrder)
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

private struct FirearmCardView: View {
    let firearm: Firearm
    let configuration: ResolvedFirearmConfiguration
    let showsExpandedCards: Bool
    let showValueInCard: Bool
    let effectiveValueCents: Int
    let onTap: () -> Void
    let onSelectCaliber: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Button(action: onTap) {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(alignment: .firstTextBaseline, spacing: 12) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(firearm.displayName)
                                .font(.headline)
                                .foregroundStyle(.primary)
                            if showsExpandedCards {
                                Text(firearm.subtitle)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        Spacer()

                        Text(firearm.firearmType.displayName)
                            .font(.caption.weight(.semibold))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Color(.tertiarySystemFill), in: Capsule())
                    }

                    AnimatedExpandableSection(isExpanded: showsExpandedCards) {
                        VStack(alignment: .leading, spacing: 6) {
                            LabeledContent("Action", value: firearm.actionDisplayName)

                            if let barrelLengthText = Firearm.barrelLengthText(for: configuration.barrelLengthInches) {
                                LabeledContent("Barrel", value: barrelLengthText)
                            }

                            if showValueInCard, effectiveValueCents > 0 {
                                LabeledContent("Value", value: KitValueService.currencyText(for: effectiveValueCents))
                            }

                            if let notes = firearm.notes, !notes.isEmpty {
                                Text(notes)
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                                    .padding(.top, 4)
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            AnimatedExpandableSection(isExpanded: showsExpandedCards && configuration.caliber != nil) {
                if let caliber = configuration.caliber {
                    Button(action: onSelectCaliber) {
                        let quantity = caliber.ammoTypes.reduce(0) { $0 + max(0, $1.quantity) }
                        LabeledContent("Caliber", value: "\(caliber.name) • \(AmmoType.roundsText(for: quantity))")
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(16)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

private struct FirearmDropDelegate: DropDelegate {
    let targetFirearm: Firearm
    let firearms: [Firearm]
    @Binding var draggedFirearm: Firearm?
    let onMove: (IndexSet, Int) -> Void

    func dropEntered(info: DropInfo) {
        guard let draggedFirearm else {
            return
        }
        guard draggedFirearm.persistentModelID != targetFirearm.persistentModelID else {
            return
        }
        guard
            let fromIndex = firearms.firstIndex(where: { $0.persistentModelID == draggedFirearm.persistentModelID }),
            let toIndex = firearms.firstIndex(where: { $0.persistentModelID == targetFirearm.persistentModelID })
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
        draggedFirearm = nil
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

#Preview {
    FirearmsView()
}
