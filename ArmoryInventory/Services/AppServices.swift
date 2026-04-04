//
//  AppServices.swift
//  Armory Inventory
//
//  Created by Codex on 4/2/26.
//

import Foundation

final class AppServices {
    static let shared = AppServices()

    private var factories: [ObjectIdentifier: () -> Any] = [:]
    private var didStart = false

    private init() {}

    func start() {
        guard !didStart else {
            return
        }

        register(AmmoChangeServicing.self) {
            AmmoChangeService()
        }

        register(InventoryTaxRateProviding.self) {
            UserDefaultsInventoryTaxRateProvider()
        }

        register(FeedbackServicing.self) {
            FeedbackService()
        }

        register(AddFirearmLookupServicing.self) {
            AddFirearmLookupService()
        }

        register(InventoryListServicing.self) {
            InventoryListService()
        }

        register(CaliberQueryServicing.self) {
            CaliberQueryService()
        }

        register(OpticLookupServicing.self) {
            OpticLookupService()
        }

        register(UserDataTransferServicing.self) {
            UserDataTransferService()
        }

        didStart = true
    }

    func register<Service>(_ type: Service.Type, factory: @escaping () -> Service) {
        factories[ObjectIdentifier(type)] = factory
    }

    func resolve<Service>(_ type: Service.Type = Service.self) -> Service {
        if !didStart {
            start()
        }

        guard let service = factories[ObjectIdentifier(type)]?() as? Service else {
            fatalError("Service not registered: \(type)")
        }
        return service
    }
}
