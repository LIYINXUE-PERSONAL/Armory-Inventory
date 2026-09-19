//
//  SettingsView.swift
//  Armory Inventory
//
//  Created by Yinxue Li on 4/2/26.
//

import SwiftUI

struct SettingsView: View {
    @State private var selection: SettingsDestination? = .about

    var body: some View {
        NavigationSplitView(columnVisibility: .constant(.all)) {
            List(selection: $selection) {
                Section("General") {
                    NavigationLink(value: SettingsDestination.about) {
                        Label("About", systemImage: "info.circle")
                    }

                    NavigationLink(value: SettingsDestination.userData) {
                        Label("User Data", systemImage: "externaldrive.badge.person.crop")
                    }

                    NavigationLink(value: SettingsDestination.taxRate) {
                        Label("Tax Rate", systemImage: "percent")
                    }

                    NavigationLink(value: SettingsDestination.valueDisplay) {
                        Label("Value Display", systemImage: "dollarsign.circle")
                    }
                }

                Section("Firearms") {
                    NavigationLink(value: SettingsDestination.firearmsSorting) {
                        Label("Firearms Sorting", systemImage: "arrow.up.arrow.down")
                    }
                }

                Section("Ammo") {
                    NavigationLink(value: SettingsDestination.caliberSorting) {
                        Label("Caliber Sorting", systemImage: "arrow.up.arrow.down")
                    }
                }

                Section("Accessories") {
                    NavigationLink(value: SettingsDestination.opticsSorting) {
                        Label("Optics Sorting", systemImage: "arrow.up.arrow.down")
                    }

                    NavigationLink(value: SettingsDestination.attachmentsSorting) {
                        Label("Attachments Sorting", systemImage: "arrow.up.arrow.down")
                    }

                    NavigationLink(value: SettingsDestination.partsSorting) {
                        Label("Parts Sorting", systemImage: "arrow.up.arrow.down")
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color(.systemBackground))
            .navigationTitle("Settings")
            .toolbar(removing: .sidebarToggle)
            .containerBackground(Color(.systemBackground), for: .navigation)
        } detail: {
            destination(for: selection ?? .about)
        }
    }

    @ViewBuilder
    private func destination(for destination: SettingsDestination) -> some View {
        switch destination {
        case .about:
            AboutView()
        case .userData:
            UserDataSettingsView()
        case .taxRate:
            TaxRateSettingsView()
        case .valueDisplay:
            ValueDisplaySettingsView()
        case .firearmsSorting:
            FirearmsSortingView()
        case .caliberSorting:
            CaliberRankingSectionView(viewModel: CaliberRankingSectionViewModel())
        case .opticsSorting:
            OpticTypeOrderingView(viewModel: OpticTypeOrderingViewModel())
        case .attachmentsSorting:
            AttachmentTypeOrderingView(viewModel: AttachmentTypeOrderingViewModel())
        case .partsSorting:
            PartTypeOrderingView(viewModel: PartTypeOrderingViewModel())
        }
    }
}

private enum SettingsDestination: Hashable {
    case about
    case userData
    case taxRate
    case valueDisplay
    case firearmsSorting
    case caliberSorting
    case opticsSorting
    case attachmentsSorting
    case partsSorting
}
