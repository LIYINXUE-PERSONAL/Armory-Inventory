//
//  OpticsModels.swift
//  Armory Inventory
//
//  Created by Codex on 4/2/26.
//

import Foundation
import SwiftData

enum OpticType: String, Codable, CaseIterable, Identifiable {
    case redDot
    case holographic
    case prism
    case lpvo
    case scope
    case magnifier
    case other

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .redDot:
            return "Red Dot"
        case .holographic:
            return "Holographic"
        case .prism:
            return "Prism"
        case .lpvo:
            return "LPVO"
        case .scope:
            return "Scope"
        case .magnifier:
            return "Magnifier"
        case .other:
            return "Other"
        }
    }

    var defaultFootprint: OpticFootprint? {
        switch self {
        case .scope, .lpvo:
            return .picatinny
        default:
            return nil
        }
    }

}

enum OpticFootprint: String, Codable, CaseIterable, Identifiable {
    case picatinny
    case weaver
    case rmr
    case rmsc
    case doctor
    case deltaPointPro
    case aimpointMicro
    case acro
    case cMore
    case other

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .picatinny:
            return "Picatinny"
        case .weaver:
            return "Weaver"
        case .rmr:
            return "RMR"
        case .rmsc:
            return "RMSc"
        case .doctor:
            return "Docter/Noblex"
        case .deltaPointPro:
            return "DeltaPoint Pro"
        case .aimpointMicro:
            return "Aimpoint Micro"
        case .acro:
            return "ACRO"
        case .cMore:
            return "C-More RTS/STS"
        case .other:
            return "Other"
        }
    }
}

enum OpticFocalPlane: String, Codable, CaseIterable, Identifiable {
    case first
    case second

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .first:
            return "FFP"
        case .second:
            return "SFP"
        }
    }
}

@Model
final class Optic {
    var id: UUID?
    var brand: String
    var modelName: String
    var type: OpticType.RawValue
    @Attribute(.unique) var serialNumber: String?
    var minMagnification: Double
    var maxMagnification: Double
    var footprint: OpticFootprint.RawValue
    var footprintDetail: String?
    var tubeSizeMillimeters: Double?
    var reticle: String?
    var focalPlane: OpticFocalPlane.RawValue?
    var isIlluminated: Bool
    var color: FirearmColor.RawValue?
    var colorDetail: String?
    var purchaseDate: Date
    var purchasePriceCents: Int
    var notes: String?
    var sortOrder: Int
    var createdAt: Date

    @Relationship var firearm: Firearm?

    init(
        id: UUID? = UUID(),
        brand: String,
        modelName: String,
        type: OpticType,
        serialNumber: String? = nil,
        minMagnification: Double,
        maxMagnification: Double,
        footprint: OpticFootprint,
        footprintDetail: String? = nil,
        tubeSizeMillimeters: Double? = nil,
        reticle: String? = nil,
        focalPlane: OpticFocalPlane? = nil,
        isIlluminated: Bool = false,
        color: FirearmColor? = nil,
        colorDetail: String? = nil,
        purchaseDate: Date = .now,
        purchasePriceCents: Int,
        notes: String? = nil,
        firearm: Firearm? = nil,
        sortOrder: Int = 0,
        createdAt: Date = .now
    ) {
        self.id = id
        self.brand = brand
        self.modelName = modelName
        self.type = type.rawValue
        self.serialNumber = serialNumber
        self.minMagnification = minMagnification
        self.maxMagnification = maxMagnification
        self.footprint = footprint.rawValue
        self.footprintDetail = footprintDetail
        self.tubeSizeMillimeters = tubeSizeMillimeters
        self.reticle = reticle
        self.focalPlane = focalPlane?.rawValue
        self.isIlluminated = isIlluminated
        self.color = color?.rawValue
        self.colorDetail = colorDetail
        self.purchaseDate = purchaseDate
        self.purchasePriceCents = purchasePriceCents
        self.notes = notes
        self.firearm = firearm
        self.sortOrder = sortOrder
        self.createdAt = createdAt
    }

    var opticType: OpticType {
        OpticType(rawValue: type) ?? .other
    }

    var opticFocalPlane: OpticFocalPlane? {
        guard let focalPlane else {
            return nil
        }
        return OpticFocalPlane(rawValue: focalPlane)
    }

    var opticFootprint: OpticFootprint {
        OpticFootprint(rawValue: footprint) ?? .other
    }

    var footprintDisplayName: String {
        if opticFootprint == .other, let footprintDetail, !footprintDetail.isEmpty {
            return footprintDetail
        }
        return opticFootprint.displayName
    }

    var opticColor: FirearmColor? {
        guard let color else {
            return nil
        }
        return FirearmColor(rawValue: color) ?? .other
    }

    var colorDisplayName: String? {
        guard let opticColor else {
            return nil
        }
        if opticColor == .other, let colorDetail, !colorDetail.isEmpty {
            return colorDetail
        }
        return opticColor.displayName
    }

    var displayName: String {
        "\(brand) \(modelName)"
    }

    var typeDisplayName: String {
        opticType.displayName
    }

    var magnificationText: String {
        let minText = minMagnification.formatted(.number.precision(.fractionLength(0...1)))
        let maxText = maxMagnification.formatted(.number.precision(.fractionLength(0...1)))
        if minMagnification == maxMagnification {
            return "\(maxText)x"
        }
        return "\(minText)-\(maxText)x"
    }

    var tubeSizeText: String? {
        guard let tubeSizeMillimeters else {
            return nil
        }
        let sizeText = tubeSizeMillimeters.formatted(.number.precision(.fractionLength(0...1)))
        return "\(sizeText) mm"
    }

    var purchasePriceText: String {
        let amount = Decimal(purchasePriceCents) / 100
        return amount.formatted(.currency(code: Locale.current.currency?.identifier ?? "USD"))
    }
}
