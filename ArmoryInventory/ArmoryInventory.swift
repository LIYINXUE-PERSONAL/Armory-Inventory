//
//  ArmoryInventory.swift
//  Armory Inventory
//
//  Created by Yinxue Li on 4/2/26.
//

import SwiftUI
import SwiftData

final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        AppServices.shared.start()
        return true
    }
}

struct RootTabView: View {
    var body: some View {
        TabView {
            FirearmsView()
                .tabItem {
                    Label("Firearms", systemImage: "shield.lefthalf.filled")
                }

            CaliberListView(viewModel: CaliberListViewModel())
                .tabItem {
                    Label("Ammo", systemImage: "eject.fill")
                }

            AccessoriesView()
                .tabItem {
                    Label("Accessories", systemImage: "wrench.and.screwdriver")
                }

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
        }
    }
}

@main
struct ArmoryInventory: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Caliber.self,
            AmmoType.self,
            AmmoAdjustmentRecord.self,
            Firearm.self,
            Optic.self,
            Magazine.self,
            Attachment.self,
            Part.self,
            Kit.self,
            KitComponent.self,
            KitHistoryRecord.self,
        ])
        let storeURL = URL.applicationSupportDirectory
            .appending(path: "ArmoryInventory.store")
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            url: storeURL
        )

        do {
            let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
            backfillMissingIDs(in: container)
            return container
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            RootTabView()
        }
        .modelContainer(sharedModelContainer)
    }

    private static func backfillMissingIDs(in container: ModelContainer) {
        let context = ModelContext(container)
        var didChange = false

        if let firearms = try? context.fetch(FetchDescriptor<Firearm>()) {
            for firearm in firearms where firearm.id == nil {
                firearm.id = UUID()
                didChange = true
            }
        }

        if let optics = try? context.fetch(FetchDescriptor<Optic>()) {
            for optic in optics where optic.id == nil {
                optic.id = UUID()
                didChange = true
            }
        }

        if let magazines = try? context.fetch(FetchDescriptor<Magazine>()) {
            for magazine in magazines where magazine.id == nil {
                magazine.id = UUID()
                didChange = true
            }
        }

        if MagazinePatternMigration.backfillMissingPatterns(in: context) {
            didChange = true
        }

        if let attachments = try? context.fetch(FetchDescriptor<Attachment>()) {
            for attachment in attachments where attachment.id == nil {
                attachment.id = UUID()
                didChange = true
            }
        }

        if let parts = try? context.fetch(FetchDescriptor<Part>()) {
            for part in parts where part.id == nil {
                part.id = UUID()
                didChange = true
            }
        }

        if let kits = try? context.fetch(FetchDescriptor<Kit>()) {
            for kit in kits where kit.id == nil {
                kit.id = UUID()
                didChange = true
            }
        }

        if let components = try? context.fetch(FetchDescriptor<KitComponent>()) {
            for component in components where component.id == nil {
                component.id = UUID()
                didChange = true
            }
        }

        guard didChange else {
            return
        }

        do {
            try context.save()
            UserDefaults.standard.set(Date(), forKey: "LastModelSaveDate")
        } catch {
            assertionFailure("Failed to backfill missing IDs: \(error)")
        }
    }
}
