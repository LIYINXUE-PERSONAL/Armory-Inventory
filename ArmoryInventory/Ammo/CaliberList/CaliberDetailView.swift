//
//  CaliberDetailView.swift
//  Armory Inventory
//
//  Created by Codex on 4/2/26.
//

import SwiftUI
import SwiftData

struct CaliberDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @State private var showingAddAmmoType = false
    @State private var selectedAmmoForAdjustment: AmmoType?
    @State private var showingCannotDeleteCaliberAlert = false
    let caliber: Caliber
    let viewModel: CaliberListViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(caliber.name)
                        .font(.largeTitle.weight(.bold))
                    Text(AmmoType.roundsText(for: viewModel.totalRounds(for: caliber)))
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }

                if viewModel.sortedAmmo(for: caliber).isEmpty {
                    ContentUnavailableView(
                        "No Ammo Yet",
                        systemImage: "shippingbox",
                        description: Text("Add a load for \(caliber.name) to start tracking your round count.")
                    )
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 32)
                } else {
                    VStack(alignment: .leading, spacing: 20) {
                        if !viewModel.inStockSortedAmmo(for: caliber).isEmpty {
                            ammoSection(title: Text("In Stock"), ammo: viewModel.inStockSortedAmmo(for: caliber))
                        }

                        if !viewModel.outOfStockSortedAmmo(for: caliber).isEmpty {
                            ammoSection(title: Text("Out of Stock"), ammo: viewModel.outOfStockSortedAmmo(for: caliber))
                        }
                    }
                }
            }
            .padding()
        }
        .navigationTitle(caliber.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button {
                    showingAddAmmoType = true
                } label: {
                    Image(systemName: "plus")
                }

                Menu {
                    Button(role: .destructive) {
                        deleteCaliber()
                    } label: {
                        Label("Delete Caliber", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                }
            }
        }
        .alert("Cannot Delete Caliber", isPresented: $showingCannotDeleteCaliberAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("A firearm is currently using this caliber, so it cannot be deleted.")
        }
        .sheet(isPresented: $showingAddAmmoType) {
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
                    viewModel.deleteAmmo(ammo, in: context)
                }
            )
            .presentationDetents([.medium, .large])
        }
    }

    @ViewBuilder
    private func ammoSection(title: Text, ammo: [AmmoType]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            title
                .font(.headline)

            Grid(horizontalSpacing: 12, verticalSpacing: 12) {
                ForEach(viewModel.ammoRows(for: ammo), id: \.self) { row in
                    GridRow {
                        ForEach(row) { ammo in
                            Button {
                                selectedAmmoForAdjustment = ammo
                            } label: {
                                AmmoCardView(
                                    ammo: ammo,
                                    backgroundStyle: AmmoCardView.backgroundStyle(for: ammo)
                                )
                            }
                            .buttonStyle(.plain)
                            .accessibilityHint("Opens ammo details for editing")
                        }

                        if row.count == 1 {
                            Color.clear
                        }
                    }
                }
            }
        }
    }

    private func deleteCaliber() {
        if viewModel.hasLinkedFirearms(caliber) {
            showingCannotDeleteCaliberAlert = true
            return
        }

        viewModel.deleteCaliber(caliber, in: context)
        dismiss()
    }
}
