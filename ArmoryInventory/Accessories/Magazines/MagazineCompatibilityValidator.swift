//
//  MagazineCompatibilityValidator.swift
//  Armory Inventory
//
//  Created by Codex on 4/22/26.
//

import Foundation
import SwiftData

struct MagazineCompatibilityValidationResult: Equatable {
    enum Failure: Equatable {
        case caliberMismatch(magazineCaliberName: String, firearmCaliberName: String)
        case patternNotSelected(patternName: String)

        var message: String {
            switch self {
            case let .caliberMismatch(magazineCaliberName, firearmCaliberName):
                return "Magazine caliber \(magazineCaliberName) does not match firearm caliber \(firearmCaliberName)."
            case let .patternNotSelected(patternName):
                return "\(patternName) is not included in this firearm's selected magazine patterns."
            }
        }
    }

    let failure: Failure?

    var isCompatible: Bool {
        failure == nil
    }

    var message: String? {
        failure?.message
    }

    static let compatible = MagazineCompatibilityValidationResult(failure: nil)
}

struct MagazineCompatibilityValidator {
    func validate(
        magazine: Magazine,
        firearmType: FirearmType,
        action: FirearmAction,
        caliber: Caliber?,
        owningFirearm: Firearm?
    ) -> MagazineCompatibilityValidationResult {
        return validate(
            pattern: magazine.resolvedPattern,
            selectedMagazineCaliber: magazine.caliber,
            firearmType: firearmType,
            action: action,
            caliber: caliber,
            firearmDescription: owningFirearm?.displayName ?? ""
        )
    }

    func validate(
        pattern: MagazinePattern,
        selectedMagazineCaliber: Caliber?,
        firearmType: FirearmType,
        action: FirearmAction,
        caliber: Caliber?,
        firearmDescription: String
    ) -> MagazineCompatibilityValidationResult {
        if let firearmCaliberName = trimmedName(caliber?.name) {
            let supportedMagazineCalibers = pattern.compatibility.supportedCaliberNames
                .compactMap(trimmedName)

            if !supportedMagazineCalibers.isEmpty,
               !supportedMagazineCalibers.contains(where: {
                   $0.caseInsensitiveCompare(firearmCaliberName) == .orderedSame
               }) {
                return .init(
                    failure: .caliberMismatch(
                        magazineCaliberName: supportedMagazineCalibers.joined(separator: ", "),
                        firearmCaliberName: firearmCaliberName
                    )
                )
            }

            if supportedMagazineCalibers.isEmpty,
               let selectedMagazineCaliberName = trimmedName(selectedMagazineCaliber?.name),
               selectedMagazineCaliberName.caseInsensitiveCompare(firearmCaliberName) != .orderedSame {
                return .init(
                    failure: .caliberMismatch(
                        magazineCaliberName: selectedMagazineCaliberName,
                        firearmCaliberName: firearmCaliberName
                    )
                )
            }
        }

        return .compatible
    }

    func firstFailure(
        magazines: [Magazine],
        firearmType: FirearmType,
        action: FirearmAction,
        caliber: Caliber?,
        owningFirearm: Firearm?
    ) -> MagazineCompatibilityValidationResult {
        for magazine in magazines {
            let result = validate(
                magazine: magazine,
                firearmType: firearmType,
                action: action,
                caliber: caliber,
                owningFirearm: owningFirearm
            )
            if !result.isCompatible {
                return result
            }
        }

        return .compatible
    }
    private func trimmedName(_ value: String?) -> String? {
        guard let value else {
            return nil
        }

        let trimmedValue = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedValue.isEmpty ? nil : trimmedValue
    }
}
