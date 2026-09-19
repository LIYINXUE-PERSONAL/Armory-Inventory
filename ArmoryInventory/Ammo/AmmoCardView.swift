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
    let backgroundStyle: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(brandLine)
                    .font(.headline)
                    .foregroundStyle(.white.opacity(0.92))
                Text(ammo.loadDescription)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.78))
            }

            Spacer(minLength: 0)

            if ammo.quantity > 0 {
                Text(AmmoType.roundsText(for: ammo.quantity))
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
            }

            if showValueInCard, ammo.centsPerRound > 0, ammo.quantity > 0 {
                Text(ammo.totalValueText)
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.82))
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(backgroundStyle.gradient, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var brandLine: String {
        if let productName = ammo.productName, !productName.isEmpty {
            return "\(ammo.brand) \(productName)"
        }
        return ammo.brand
    }

    static func backgroundStyle(for ammo: AmmoType) -> Color {
        let palette: [Color] = [
            Color(red: 0.14, green: 0.36, blue: 0.60),
            Color(red: 0.10, green: 0.52, blue: 0.44),
            Color(red: 0.69, green: 0.44, blue: 0.12),
            Color(red: 0.45, green: 0.28, blue: 0.70),
            Color(red: 0.66, green: 0.20, blue: 0.32),
            Color(red: 0.28, green: 0.42, blue: 0.23)
        ]
        let hashValue = abs("\(ammo.brand)-\(ammo.bulletType)-\(ammo.grain)".hashValue)
        return palette[hashValue % palette.count]
    }
}
