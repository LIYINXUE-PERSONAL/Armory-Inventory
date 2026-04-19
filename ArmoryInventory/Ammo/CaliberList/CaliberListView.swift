//
//  CaliberListView.swift
//  Armory Inventory
//
//  Created by Yinxue Li on 4/2/26.
//

import SwiftUI
import SwiftData

struct CaliberListView: View {
    @Environment(\.modelContext) private var context
    @Query private var calibers: [Caliber]
    @AppStorage(CaliberSort.settingsVersionKey) private var sortVersion = 0
    @AppStorage(InventorySettingsKeys.showTotalValue) private var showTotalValue = true
    @State private var showingAddCaliber = false
    @State private var selectedCaliberForAmmo: Caliber?
    @State private var selectedAmmoForAdjustment: AmmoType?
    @State private var expandedCaliberIDs: Set<PersistentIdentifier> = []
    @State private var didInitializeCollapsedState = false
    @State private var knownCaliberIDs: Set<PersistentIdentifier> = []
    let viewModel: CaliberListViewModel

    var body: some View {
        NavigationStack {
            Group {
                if sortedCalibers.isEmpty {
                    ContentUnavailableView(
                        "No Ammo Yet",
                        systemImage: "shippingbox",
                        description: Text("Add your first caliber or ammo type to start tracking your inventory.")
                    )
                } else {
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 20) {
                            ForEach(sortedCalibers) { caliber in
                                VStack(alignment: .leading, spacing: 12) {
                                    HStack(alignment: .firstTextBaseline) {
                                        NavigationLink {
                                            CaliberDetailView(caliber: caliber, viewModel: viewModel)
                                        } label: {
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(caliber.name)
                                                    .font(.title3.weight(.semibold))
                                                    .foregroundStyle(.primary)
                                                Text(AmmoType.roundsText(for: viewModel.totalRounds(for: caliber)))
                                                    .font(.subheadline)
                                                    .foregroundStyle(.secondary)
                                            }
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .contentShape(Rectangle())
                                        }
                                        .buttonStyle(.plain)
                                        Spacer()
                                        Button {
                                            withAnimation(.easeInOut(duration: 0.2)) {
                                                toggleCollapsedState(for: caliber)
                                            }
                                        } label: {
                                            Image(systemName: "chevron.down")
                                                .font(.headline)
                                                .rotationEffect(.degrees(isCollapsed(caliber) ? 0 : 180))
                                                .animation(.easeInOut(duration: 0.2), value: isCollapsed(caliber))
                                        }
                                        .buttonStyle(.borderless)
                                    }

                                    if !isCollapsed(caliber) {
                                        Group {
                                            if caliber.ammoTypes.isEmpty {
                                                ContentUnavailableView(
                                                    "No Ammo Yet",
                                                    systemImage: "shippingbox",
                                                    description: Text("Add a load for \(caliber.name) to start tracking your round count.")
                                                )
                                                .frame(maxWidth: .infinity)
                                                .padding(.vertical, 12)
                                            } else if viewModel.inStockSortedAmmo(for: caliber).isEmpty {
                                                ContentUnavailableView(
                                                    "No Ammo In Stock",
                                                    systemImage: "exclamationmark.circle",
                                                    description: Text("Open \(caliber.name) to view out-of-stock loads.")
                                                )
                                                .frame(maxWidth: .infinity)
                                                .padding(.vertical, 12)
                                            } else {
                                                Grid(horizontalSpacing: 12, verticalSpacing: 12) {
                                                    ForEach(viewModel.ammoRows(for: caliber, includeOutOfStock: false), id: \.self) { row in
                                                        GridRow {
                                                            ForEach(row) { ammo in
                                                                AmmoCardView(
                                                                    ammo: ammo,
                                                                    backgroundStyle: AmmoCardView.backgroundStyle(for: ammo)
                                                                )
                                                                .onTapGesture {
                                                                    selectedAmmoForAdjustment = ammo
                                                                }
                                                            }

                                                            if row.count == 1 {
                                                                Color.clear
                                                            }
                                                        }
                                                    }
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
            .navigationTitle("Ammunition")
            .onAppear {
                initializeCollapsedStateIfNeeded()
            }
            .onChange(of: calibers.count) {
                syncCollapsedCalibers()
            }
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    NavigationLink {
                        AmmoHistoryView(viewModel: CaliberListViewModel())
                    } label: {
                        Image(systemName: "clock.arrow.trianglehead.counterclockwise.rotate.90")
                    }

                    Button {
                        showingAddCaliber = true
                    } label: {
                        Label("Add Caliber", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddCaliber) {
                AddCaliberView(viewModel: AddCaliberViewModel())
                    .presentationDetents([.medium])
            }
            .sheet(item: $selectedCaliberForAmmo) { caliber in
                AddAmmoTypeView(caliber: caliber, viewModel: AddAmmoTypeViewModel())
                    .presentationDetents([.large])
            }
            .sheet(item: $selectedAmmoForAdjustment) { ammo in
                AdjustAmmoQuantityView(
                    ammo: ammo,
                    viewModel: AdjustAmmoQuantityViewModel(),
                    onApply: { delta, occurredAt in
                        viewModel.adjustQuantity(for: ammo, by: delta, occurredAt: occurredAt, in: context)
                    },
                    onDelete: {
                        selectedAmmoForAdjustment = nil
                        deleteAmmo(ammo)
                    }
                )
                .presentationDetents([.medium, .large])
            }
        }
    }

    private var sortedCalibers: [Caliber] {
        _ = sortVersion
        return viewModel.sortedCalibers(from: calibers)
    }

    private func deleteAmmo(_ ammo: AmmoType) {
        viewModel.deleteAmmo(ammo, in: context)
    }

    private func deleteCaliber(_ caliber: Caliber) {
        expandedCaliberIDs.remove(caliber.persistentModelID)
        if viewModel.shouldClearSelectedCaliber(selectedCaliberForAmmo?.persistentModelID, deleting: caliber) {
            selectedCaliberForAmmo = nil
        }
        viewModel.deleteCaliber(caliber, in: context)
    }

    private func isCollapsed(_ caliber: Caliber) -> Bool {
        !expandedCaliberIDs.contains(caliber.persistentModelID)
    }

    private func toggleCollapsedState(for caliber: Caliber) {
        let caliberID = caliber.persistentModelID
        if expandedCaliberIDs.contains(caliberID) {
            expandedCaliberIDs.remove(caliberID)
        } else {
            expandedCaliberIDs.insert(caliberID)
        }
    }

    private func initializeCollapsedStateIfNeeded() {
        guard !didInitializeCollapsedState else {
            return
        }
        let currentIDs = Set(sortedCalibers.map(\.persistentModelID))
        expandedCaliberIDs = []
        knownCaliberIDs = currentIDs
        didInitializeCollapsedState = true
    }

    private func syncCollapsedCalibers() {
        guard didInitializeCollapsedState else {
            return
        }
        let currentIDs = Set(sortedCalibers.map(\.persistentModelID))
        expandedCaliberIDs = expandedCaliberIDs.intersection(currentIDs)
        knownCaliberIDs = currentIDs
    }

    private var totalValueText: String {
        viewModel.totalValueText(
            for: sortedCalibers,
            currencyCode: Locale.current.currency?.identifier ?? "USD"
        )
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

#Preview {
    let preview = Previewer()
    return CaliberListView(viewModel: CaliberListViewModel())
        .modelContainer(preview.container)
}

// Simple preview helper to seed data
@MainActor
private struct Previewer {
    let container: ModelContainer

    init() {
        let schema = Schema([Caliber.self, AmmoType.self, AmmoAdjustmentRecord.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        container = try! ModelContainer(for: schema, configurations: [config])
        let nine = Caliber(name: "9mm")
        let twoTwoThree = Caliber(name: ".223 Rem")
        container.mainContext.insert(nine)
        container.mainContext.insert(twoTwoThree)
        let federal = AmmoType(brand: "Federal", bulletType: "FMJ", grain: 115, quantity: 250, caliber: nine)
        let hornady = AmmoType(brand: "Hornady", bulletType: "JHP", grain: 124, quantity: 50, caliber: nine)
        let pmc = AmmoType(brand: "PMC", bulletType: "FMJ", grain: 55, quantity: 180, caliber: twoTwoThree)
        container.mainContext.insert(federal)
        container.mainContext.insert(hornady)
        container.mainContext.insert(pmc)
        container.mainContext.insert(AmmoAdjustmentRecord(quantity: 300, kind: .purchase, caliber: nine, ammoType: federal))
        container.mainContext.insert(AmmoAdjustmentRecord(quantity: 75, kind: .consumption, caliber: nine, ammoType: federal))
        container.mainContext.insert(AmmoAdjustmentRecord(quantity: 50, kind: .purchase, caliber: nine, ammoType: hornady))
        container.mainContext.insert(AmmoAdjustmentRecord(quantity: 20, kind: .consumption, caliber: nine, ammoType: hornady))
        container.mainContext.insert(
            AmmoAdjustmentRecord(
                quantity: 180,
                occurredAt: Calendar.current.date(byAdding: .day, value: -5, to: .now) ?? .now,
                kind: .purchase,
                caliber: twoTwoThree,
                ammoType: pmc
            )
        )
        container.mainContext.insert(
            AmmoAdjustmentRecord(
                quantity: 40,
                occurredAt: Calendar.current.date(byAdding: .day, value: -3, to: .now) ?? .now,
                kind: .consumption,
                caliber: twoTwoThree,
                ammoType: pmc
            )
        )
    }
}
