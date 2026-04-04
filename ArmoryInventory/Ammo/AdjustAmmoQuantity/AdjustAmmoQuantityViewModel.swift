//
//  AdjustAmmoQuantityViewModel.swift
//  Armory Inventory
//
//  Created by Yinxue Li on 4/2/26.
//

import Foundation

final class AdjustAmmoQuantityViewModel {
    func canApply(quantityDeltaText: String, currentQuantity: Int, multiplier: Int) -> Bool {
        guard let quantityDelta = parsedQuantityDelta(from: quantityDeltaText), quantityDelta > 0 else {
            return false
        }

        let resultingQuantity = currentQuantity + (quantityDelta * multiplier)
        return resultingQuantity >= 0
    }

    func deltaToApply(quantityDeltaText: String, currentQuantity: Int, multiplier: Int) -> Int? {
        guard canApply(
            quantityDeltaText: quantityDeltaText,
            currentQuantity: currentQuantity,
            multiplier: multiplier
        ) else {
            return nil
        }

        guard let quantityDelta = parsedQuantityDelta(from: quantityDeltaText) else {
            return nil
        }

        return quantityDelta * multiplier
    }

    private func parsedQuantityDelta(from quantityDeltaText: String) -> Int? {
        Int(quantityDeltaText)
    }
}
