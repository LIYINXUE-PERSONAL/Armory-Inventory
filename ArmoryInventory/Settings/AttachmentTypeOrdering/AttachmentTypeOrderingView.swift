//
//  AttachmentTypeOrderingView.swift
//  Armory Inventory
//
//  Created by Codex on 4/2/26.
//

import SwiftUI

struct AttachmentTypeOrderingView: View {
    @AppStorage(AttachmentTypeSort.settingsVersionKey) private var sortVersion = 0
    @State private var rankingNames: [String] = []
    let viewModel: AttachmentTypeOrderingViewModel

    var body: some View {
        List {
            Section {
                Text("Hold and drag attachment types to control the section order used in attachments.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Section("Order") {
                ForEach(rankingNames, id: \.self) { typeName in
                    Text(viewModel.displayName(for: typeName))
                }
                .onMove(perform: moveRanking)
            }

            Section {
                Button("Reset to Default Order", role: .destructive) {
                    viewModel.resetOrder(rankingNames: &rankingNames)
                }
            }
        }
        .navigationTitle("Attachments Sorting")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                EditButton()
            }
        }
        .onAppear {
            rankingNames = viewModel.refreshedRankingNames()
        }
        .onChange(of: sortVersion) { _, _ in
            rankingNames = viewModel.refreshedRankingNames()
        }
    }

    private func moveRanking(from source: IndexSet, to destination: Int) {
        rankingNames = viewModel.moveRanking(rankingNames, from: source, to: destination)
    }
}
