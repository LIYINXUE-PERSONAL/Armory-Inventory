//
//  AddCaliberViewModel.swift
//  Armory Inventory
//
//  Created by Yinxue Li on 4/2/26.
//

import Foundation
import SwiftData

final class AddCaliberViewModel {
    func selectedName(selectedCaliberName: String, customName: String, customOption: String) -> String {
        let rawName = selectedCaliberName == customOption ? customName : selectedCaliberName
        return rawName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func duplicateExists(named selectedName: String, in existingCalibers: [Caliber]) -> Bool {
        existingCalibers.contains {
            $0.name.compare(selectedName, options: [.caseInsensitive, .diacriticInsensitive]) == .orderedSame
        }
    }

    func canAdd(selectedName: String, duplicateExists: Bool) -> Bool {
        !selectedName.isEmpty && !duplicateExists
    }

    func commonCaliberNames(excluding existingCalibers: [Caliber]) -> [String] {
        let existingNames = Set(
            existingCalibers.map {
                $0.name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            }
        )

        let availableCalibers = CommonAmmoCatalog.defaultCaliberNames.filter {
            !existingNames.contains($0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased())
        }

        return CaliberSort.displayOrder(for: availableCalibers)
    }

    func updatedSelectedCaliberName(
        currentSelection: String,
        customOption: String,
        commonCaliberNames: [String]
    ) -> String {
        if currentSelection == customOption {
            return commonCaliberNames.first ?? customOption
        }

        if commonCaliberNames.contains(currentSelection) {
            return currentSelection
        }

        return commonCaliberNames.first ?? customOption
    }

    func addCaliber(named selectedName: String, canAdd: Bool, to context: ModelContext) -> Bool {
        guard canAdd else { return false }
        let caliber = Caliber(name: selectedName)
        context.insert(caliber)

        do {
            try context.save()
            UserDefaults.standard.set(Date(), forKey: "LastModelSaveDate")
            return true
        } catch {
            print("Save error: \(error)")
            return false
        }
    }
}
