//
//  GeneralSettingsView.swift
//  Armory Inventory
//
//  Created by Codex on 4/2/26.
//

import SwiftUI

struct ValueDisplaySettingsView: View {
    @AppStorage(InventorySettingsKeys.showValueInDetails) private var showValueInDetails = true
    @AppStorage(InventorySettingsKeys.showValueInCard) private var showValueInCard = true
    @AppStorage(InventorySettingsKeys.showTotalValue) private var showTotalValue = true

    var body: some View {
        List {
            Section("Value Display") {
                Toggle("Show Value in Details", isOn: $showValueInDetails)
                Toggle("Show Value in Card", isOn: $showValueInCard)
                Toggle("Show Total Value", isOn: $showTotalValue)
            }
        }
        .navigationTitle("Value Display")
        .navigationBarTitleDisplayMode(.inline)
    }
}
