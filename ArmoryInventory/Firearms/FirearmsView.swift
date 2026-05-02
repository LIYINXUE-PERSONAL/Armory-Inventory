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
    @State private var showsExpandedCards = false
    @State private var draggedFirearm: Firearm?

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
                                    showsExpandedCards: showsExpandedCards,
                                    showValueInCard: showValueInCard,
                                    onTap: {
                                        selectedFirearm = firearm
                                    },
                                    onSelectCaliber: {
                                        if let caliber = firearm.caliber {
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

    private func deleteFirearms(at offsets: IndexSet) {
        for index in offsets {
            context.delete(filteredFirearms[index])
        }
        resequenceFirearms()

        do {
            try context.save()
            UserDefaults.standard.set(Date(), forKey: "LastModelSaveDate")
            reloadFirearms()
        } catch {
            print("Delete error: \(error)")
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
                                Button(filterCountText(title: firearmType.displayName, count: countForType(firearmType))) {
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
                                Button(filterCountText(title: action.displayName, count: countForAction(action))) {
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

                            ForEach(availableCalibers) { caliber in
                                Button(filterCountText(title: caliber.name, count: countForCaliber(caliber))) {
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
        let filtered = firearms.filter { firearm in
            let matchesType = selectedTypeFilter == nil || firearm.firearmType == selectedTypeFilter
            let matchesAction = selectedActionFilter == nil || firearm.firearmAction == selectedActionFilter
            let matchesCaliber = selectedCaliberFilter == nil || firearm.caliber?.persistentModelID == selectedCaliberFilter?.persistentModelID
            return matchesType && matchesAction && matchesCaliber
        }

        switch selectedSortOrder {
        case .manual:
            return filtered
        case .purchaseDate:
            return filtered.sorted {
                if $0.purchaseDate != $1.purchaseDate {
                    return compare($0.purchaseDate, $1.purchaseDate)
                }
                return compareNames($0.displayName, $1.displayName)
            }
        case .value:
            return filtered.sorted {
                if $0.purchasePriceCents != $1.purchasePriceCents {
                    return compare($0.purchasePriceCents, $1.purchasePriceCents)
                }
                return compareNames($0.displayName, $1.displayName)
            }
        case .barrelLength:
            return filtered.sorted {
                let lhs = $0.barrelLengthInches ?? -1
                let rhs = $1.barrelLengthInches ?? -1
                if lhs != rhs {
                    return compare(lhs, rhs)
                }
                return compareNames($0.displayName, $1.displayName)
            }
        case .brand:
            return filtered.sorted {
                let brandComparison = $0.brand.localizedStandardCompare($1.brand)
                if brandComparison != .orderedSame {
                    return compare(brandComparison)
                }
                return compareNames($0.modelName, $1.modelName)
            }
        case .caliber:
            return filtered.sorted {
                let lhs = $0.caliber?.name ?? ""
                let rhs = $1.caliber?.name ?? ""
                let caliberComparison = lhs.localizedStandardCompare(rhs)
                if caliberComparison != .orderedSame {
                    return compare(caliberComparison)
                }
                return compareNames($0.displayName, $1.displayName)
            }
        case .type:
            return filtered.sorted {
                let typeComparison = $0.firearmType.displayName.localizedStandardCompare($1.firearmType.displayName)
                if typeComparison != .orderedSame {
                    return compare(typeComparison)
                }
                return compareNames($0.displayName, $1.displayName)
            }
        }
    }

    private func moveFirearms(from source: IndexSet, to destination: Int) {
        guard selectedSortOrder == .manual else {
            return
        }

        var reorderedFilteredFirearms = filteredFirearms
        reorderedFilteredFirearms.move(fromOffsets: source, toOffset: destination)

        var reorderedFilteredIterator = reorderedFilteredFirearms.makeIterator()
        let reorderedFirearms = firearms.map { firearm in
            let matchesType = selectedTypeFilter == nil || firearm.firearmType == selectedTypeFilter
            let matchesAction = selectedActionFilter == nil || firearm.firearmAction == selectedActionFilter

            guard matchesType && matchesAction else {
                return firearm
            }

            return reorderedFilteredIterator.next() ?? firearm
        }

        for (index, firearm) in reorderedFirearms.enumerated() {
            firearm.sortOrder = index
        }

        do {
            try context.save()
            UserDefaults.standard.set(Date(), forKey: "LastModelSaveDate")
            reloadFirearms()
        } catch {
            print("Reorder error: \(error)")
        }
    }

    private func reloadFirearms() {
        do {
            firearms = try inventoryListService.fetchFirearms(in: context)
        } catch {
            print("Firearms fetch error: \(error)")
        }
    }

    private func resequenceFirearms() {
        for (index, firearm) in firearms.enumerated() {
            firearm.sortOrder = index
        }
    }

    private func countForType(_ firearmType: FirearmType) -> Int {
        firearms.count { $0.firearmType == firearmType }
    }

    private func countForAction(_ action: FirearmAction) -> Int {
        firearms.count { $0.firearmAction == action }
    }

    private func countForCaliber(_ caliber: Caliber) -> Int {
        firearms.count { $0.caliber?.persistentModelID == caliber.persistentModelID }
    }

    private var availableCalibers: [Caliber] {
        var calibersByID: [PersistentIdentifier: Caliber] = [:]
        for firearm in firearms {
            if let caliber = firearm.caliber {
                calibersByID[caliber.persistentModelID] = caliber
            }
        }
        return calibersByID.values.sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
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
        let totalCents = filteredFirearms.reduce(0) { $0 + $1.totalCardValueCents }
        let amount = Decimal(totalCents) / 100
        return amount.formatted(.currency(code: Locale.current.currency?.identifier ?? "USD"))
    }

    private var allTypesCountText: String {
        String.localizedStringWithFormat(
            String(localized: "All Types (%lld)"),
            firearms.count.localizedCountString
        )
    }

    private var allActionsCountText: String {
        String.localizedStringWithFormat(
            String(localized: "All Actions (%lld)"),
            firearms.count.localizedCountString
        )
    }

    private var allCalibersCountText: String {
        String.localizedStringWithFormat(
            String(localized: "All Calibers (%lld)"),
            firearms.count.localizedCountString
        )
    }

    private func filterCountText(title: String, count: Int) -> String {
        String.localizedStringWithFormat(
            String(localized: "%@ (%lld)"),
            title,
            count.localizedCountString
        )
    }

    private var selectedSortOrder: FirearmSortOrder {
        FirearmSortOrder(rawValue: firearmSortOrder) ?? .manual
    }

    private var selectedSortDirection: FirearmSortDirection {
        FirearmSortDirection(rawValue: firearmSortDirectionRaw) ?? preferredDirection(for: selectedSortOrder)
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

    private func compare<T: Comparable>(_ lhs: T, _ rhs: T) -> Bool {
        switch selectedSortDirection {
        case .ascending:
            return lhs < rhs
        case .descending:
            return lhs > rhs
        }
    }

    private func compare(_ comparison: ComparisonResult) -> Bool {
        switch selectedSortDirection {
        case .ascending:
            return comparison == .orderedAscending
        case .descending:
            return comparison == .orderedDescending
        }
    }

    private func compareNames(_ lhs: String, _ rhs: String) -> Bool {
        compare(lhs.localizedStandardCompare(rhs))
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
    let showsExpandedCards: Bool
    let showValueInCard: Bool
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

                            if let barrelLengthText = firearm.barrelLengthText {
                                LabeledContent("Barrel", value: barrelLengthText)
                            }

                            if showValueInCard, firearm.totalCardValueCents > 0 {
                                LabeledContent("Value", value: firearm.totalCardValueText)
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

            AnimatedExpandableSection(isExpanded: showsExpandedCards && firearm.caliber != nil) {
                if firearm.caliber != nil {
                    Button(action: onSelectCaliber) {
                        LabeledContent("Caliber", value: "\(firearm.caliber?.name ?? "") • \(firearm.roundsText ?? AmmoType.roundsText(for: 0))")
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
