//
//  AttachmentsView.swift
//  Armory Inventory
//
//  Created by Codex on 4/2/26.
//

import SwiftUI
import SwiftData

struct AttachmentsView: View {
    @Environment(\.modelContext) private var context
    @AppStorage(AttachmentTypeSort.settingsVersionKey) private var typeSortVersion = 0
    @AppStorage(InventorySettingsKeys.attachmentItemSortOrder) private var itemSortOrder = AccessoryItemSortOrder.manual.rawValue
    @AppStorage(InventorySettingsKeys.attachmentItemSortDirection) private var itemSortDirectionRaw = ""
    @AppStorage(InventorySettingsKeys.showValueInCard) private var showValueInCard = true
    @AppStorage(InventorySettingsKeys.showTotalValue) private var showTotalValue = true
    @State private var showingAddAttachment = false
    @State private var selectedAttachment: Attachment?
    @State private var attachments: [Attachment] = []

    private let inventoryListService: InventoryListServicing = AppServices.shared.resolve(InventoryListServicing.self)

    var body: some View {
        Group {
            if attachments.isEmpty {
                ContentUnavailableView(
                    "No Attachments Yet",
                    systemImage: "paperclip",
                    description: Text("Add your first attachment to track stocks, grips, lasers, lights, and other hardware.")
                )
            } else {
                List {
                    ForEach(groupedAttachmentTypes, id: \.self) { typeID in
                        Section(attachmentTypeDisplayName(for: typeID)) {
                            ForEach(groupedAttachments[typeID] ?? []) { attachment in
                                Button {
                                    selectedAttachment = attachment
                                } label: {
                                    VStack(alignment: .leading, spacing: 6) {
                                        Text(attachment.displayName)
                                            .font(.headline)

                                        if showValueInCard, attachment.purchasePriceCents > 0 {
                                            LabeledContent("Value", value: attachment.purchasePriceText)
                                        }

                                        if let firearm = attachment.firearm {
                                            LabeledContent("Linked Firearm", value: firearm.displayName)
                                        }
                                    }
                                    .padding(.vertical, 6)
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                            }
                            .onDelete { offsets in
                                deleteAttachments(at: offsets, in: typeID)
                            }
                        }
                    }

                    if showTotalValue {
                        Section {
                            LabeledContent("Total Value", value: totalValueText)
                        }
                    }
                }
            }
        }
        .navigationTitle("Attachments")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            reloadAttachments()
        }
        .onAppear {
            reloadAttachments()
        }
        .onChange(of: showingAddAttachment) {
            if !showingAddAttachment {
                reloadAttachments()
            }
        }
        .onChange(of: selectedAttachment) {
            if selectedAttachment == nil {
                reloadAttachments()
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                EditButton()

                Button {
                    showingAddAttachment = true
                } label: {
                    Label("Add Attachment", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddAttachment) {
            AddAttachmentView(viewModel: AddAttachmentViewModel())
                .presentationDetents([.large])
        }
        .sheet(item: $selectedAttachment) { attachment in
            AddAttachmentView(attachment: attachment, viewModel: AddAttachmentViewModel())
                .presentationDetents([.large])
        }
    }

    private var groupedAttachments: [String: [Attachment]] {
        Dictionary(grouping: attachments, by: \.type).mapValues {
            AccessoryItemSort.sorted($0, by: selectedItemSortOrder, direction: selectedItemSortDirection)
        }
    }

    private var groupedAttachmentTypes: [String] {
        AttachmentTypeSort.displayOrder(for: Array(groupedAttachments.keys))
    }

    private func deleteAttachments(at offsets: IndexSet, in type: String) {
        guard let sectionAttachments = groupedAttachments[type] else {
            return
        }

        for index in offsets {
            context.delete(sectionAttachments[index])
        }
        resequenceAttachments()

        do {
            try context.save()
            UserDefaults.standard.set(Date(), forKey: "LastModelSaveDate")
            reloadAttachments()
        } catch {
            print("Delete error: \(error)")
        }
    }

    private func reloadAttachments() {
        do {
            attachments = try inventoryListService.fetchAttachments(in: context)
        } catch {
            print("Attachments fetch error: \(error)")
        }
    }

    private func resequenceAttachments() {
        for (index, attachment) in attachments.enumerated() {
            attachment.sortOrder = index
        }
    }

    private var totalValueText: String {
        let totalCents = attachments.reduce(0) { $0 + max(0, $1.purchasePriceCents) }
        let amount = Decimal(totalCents) / 100
        return amount.formatted(.currency(code: Locale.current.currency?.identifier ?? "USD"))
    }

    private func attachmentTypeDisplayName(for typeID: String) -> String {
        AttachmentType(rawValue: typeID)?.displayName ?? typeID
    }

    private var selectedItemSortOrder: AccessoryItemSortOrder {
        AccessoryItemSortOrder(rawValue: itemSortOrder) ?? .manual
    }

    private var selectedItemSortDirection: AccessoryItemSortDirection {
        AccessoryItemSortDirection(rawValue: itemSortDirectionRaw) ?? AccessoryItemSort.preferredDirection(for: selectedItemSortOrder)
    }
}
