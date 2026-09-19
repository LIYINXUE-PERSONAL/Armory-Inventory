//
//  AmmoCardView.swift
//  Armory Inventory
//
//  Created by Yinxue Li on 4/2/26.
//

import SwiftUI

struct AmmoCardView: View {
    @AppStorage(InventorySettingsKeys.showValueInCard) private var showValueInCard = true

    let ammo: AmmoType

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(brandLine)
                    .font(.headline)
                    .foregroundStyle(.primary)
                Text(ammo.loadDescription)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)

            if ammo.quantity > 0 {
                Text(AmmoType.roundsText(for: ammo.quantity))
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
            }

            if showValueInCard, ammo.centsPerRound > 0, ammo.quantity > 0 {
                Text(ammo.totalValueText)
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color("InventoryCardBackground"), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var brandLine: String {
        if let productName = ammo.productName, !productName.isEmpty {
            return "\(ammo.brand) \(productName)"
        }
        return ammo.brand
    }
}
