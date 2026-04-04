//
//  SettingsView.swift
//  Armory Inventory
//
//  Created by Yinxue Li on 4/2/26.
//

import SwiftUI

struct SettingsView: View {

    var body: some View {
        NavigationStack {
            List {
                Section("General") {
                    NavigationLink {
                        AboutView()
                    } label: {
                        Label("About", systemImage: "info.circle")
                    }
                    
                    NavigationLink {
                        UserDataSettingsView()
                    } label: {
                        Label("User Data", systemImage: "externaldrive.badge.person.crop")
                    }
                    
                    NavigationLink {
                        TaxRateSettingsView()
                    } label: {
                        Label("Tax Rate", systemImage: "percent")
                    }

                    NavigationLink {
                        ValueDisplaySettingsView()
                    } label: {
                        Label("Value Display", systemImage: "dollarsign.circle")
                    }
                }
                
                Section("Firearms") {
                    NavigationLink {
                        FirearmsSortingView()
                    } label: {
                        Label("Firearms Sorting", systemImage: "arrow.up.arrow.down")
                    }
                }
                
                Section("Ammo") {
                    NavigationLink {
                        CaliberRankingSectionView(viewModel: CaliberRankingSectionViewModel())
                    } label: {
                        Label("Caliber Sorting", systemImage: "arrow.up.arrow.down")
                    }
                }
                
                Section("Accessories"){
                    NavigationLink {
                        AttachmentTypeOrderingView(viewModel: AttachmentTypeOrderingViewModel())
                    } label: {
                        Label("Attachments Sorting", systemImage: "arrow.up.arrow.down")
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }
}
