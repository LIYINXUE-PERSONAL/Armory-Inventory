//
//  CaliberRankingSectionView.swift
//  Armory Inventory
//
//  Created by Yinxue Li on 4/2/26.
//

import SwiftUI
import SwiftData

struct CaliberRankingSectionView: View {
    @Query private var calibers: [Caliber]
    @AppStorage(CaliberSort.settingsVersionKey) private var sortVersion = 0
    @State private var rankingNames: [String] = []
    let viewModel: CaliberRankingSectionViewModel

    var body: some View {
        List {
            Section {
                Text("Hold and drag calibers to control the order used throughout the app.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Section("Order") {
                ForEach(rankingNames, id: \.self) { caliberName in
                    Text(viewModel.displayName(for: caliberName, calibers: calibers))
                }
                .onMove(perform: moveRanking)
            }

            Section {
                Button("Reset to Default Order", role: .destructive) {
                    viewModel.resetOrder(rankingNames: &rankingNames, calibers: calibers)
                }
            }
        }
        .navigationTitle("Caliber Sorting")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                EditButton()
            }
        }
        .onAppear {
            rankingNames = viewModel.refreshedRankingNames(calibers: calibers)
        }
        .onChange(of: sortVersion) { _, _ in
            rankingNames = viewModel.refreshedRankingNames(calibers: calibers)
        }
    }

    private func moveRanking(from source: IndexSet, to destination: Int) {
        rankingNames = viewModel.moveRanking(rankingNames, from: source, to: destination)
    }
}
