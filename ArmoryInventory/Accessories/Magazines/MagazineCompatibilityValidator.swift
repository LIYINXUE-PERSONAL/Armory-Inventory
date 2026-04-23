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
        case linkedToDifferentFirearm(currentFirearmName: String)
        case caliberMismatch(magazineCaliberName: String, firearmCaliberName: String)
        case incompatiblePattern(patternName: String, firearmDescription: String)

        var message: String {
            switch self {
            case let .linkedToDifferentFirearm(currentFirearmName):
                return "This magazine is already linked to \(currentFirearmName)."
            case let .caliberMismatch(magazineCaliberName, firearmCaliberName):
                return "Magazine caliber \(magazineCaliberName) does not match firearm caliber \(firearmCaliberName)."
            case let .incompatiblePattern(patternName, firearmDescription):
                return "\(patternName) is not compatible with \(firearmDescription)."
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
        if let linkedFirearm = magazine.firearm,
           linkedFirearm.persistentModelID != owningFirearm?.persistentModelID {
            return .init(failure: .linkedToDifferentFirearm(currentFirearmName: linkedFirearm.displayName))
        }

        return validate(
            pattern: magazine.resolvedPattern,
            selectedMagazineCaliber: magazine.caliber,
            firearmType: firearmType,
            action: action,
            caliber: caliber,
            firearmDescription: owningFirearm?.displayName ?? firearmDescription(type: firearmType, action: action)
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
        if let selectedMagazineCaliberName = trimmedName(selectedMagazineCaliber?.name),
           let firearmCaliberName = trimmedName(caliber?.name),
           selectedMagazineCaliberName.caseInsensitiveCompare(firearmCaliberName) != .orderedSame {
            return .init(
                failure: .caliberMismatch(
                    magazineCaliberName: selectedMagazineCaliberName,
                    firearmCaliberName: firearmCaliberName
                )
            )
        }

        let effectiveCaliberName = trimmedName(caliber?.name) ?? trimmedName(selectedMagazineCaliber?.name)
        guard pattern.isCompatible(with: firearmType, action: action, caliberName: effectiveCaliberName) else {
            return .init(
                failure: .incompatiblePattern(
                    patternName: pattern.displayName,
                    firearmDescription: firearmDescription
                )
            )
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

    private func firearmDescription(type: FirearmType, action: FirearmAction) -> String {
        "\(type.displayName) (\(action.displayName))"
    }

    private func trimmedName(_ value: String?) -> String? {
        guard let value else {
            return nil
        }

        let trimmedValue = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedValue.isEmpty ? nil : trimmedValue
    }
}
