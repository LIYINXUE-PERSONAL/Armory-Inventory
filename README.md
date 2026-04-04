# Armory Inventory

Armory Inventory is an iOS app for tracking firearms, ammunition, optics, magazines, attachments, and related collection data. The app is built with SwiftUI, persists data with SwiftData, and includes settings for sorting, tax rates, value visibility, feedback, and user data backup/import.

## Features

- Track firearms with caliber, action, type, barrel length, notes, purchase details, and value.
- Track ammunition by caliber and load, including quantity adjustments and ammo history.
- Track accessories across optics, magazines, and attachments.
- Filter firearms by type, action, and caliber.
- Reorder firearms manually or sort them by brand, caliber, type, value, purchase date, or barrel length.
- Configure caliber ranking and attachment type ordering in Settings.
- Control value visibility for detail views, cards, and total inventory summaries.
- Configure separate tax rates for firearms, ammo, and accessories.
- Export, import, and clear app data from the User Data settings screen.
- Send feedback from the About screen.

## App Structure

The app uses a four-tab layout:

- `Firearms`
- `Ammo`
- `Accessories`
- `Settings`

Core data entities currently include:

- `Firearm`
- `Caliber`
- `AmmoType`
- `AmmoAdjustmentRecord`
- `Optic`
- `Magazine`
- `Attachment`

Services are registered through `AppServices` and cover lookup, inventory listing, ammo changes, tax rates, feedback, caliber queries, optic lookup, and user data transfer.

## Tech Stack

- Swift
- SwiftUI
- SwiftData
- XCTest via the included `ArmoryInventoryTests` target

## Project Layout

```text
ArmoryInventory/
├── ArmoryInventory/
│   ├── Accessories/
│   ├── Ammo/
│   ├── Firearms/
│   ├── Services/
│   └── Settings/
└── ArmoryInventoryTests/
    ├── AccessoriesTests/
    ├── AmmoTests/
    ├── FirearmsTests/
    ├── ServicesTests/
    └── SettingsTests/
```

## Getting Started

1. Open the project in Xcode.
2. Select the `ArmoryInventory` scheme.
3. Build and run on an iPhone simulator or supported device.

## Testing

The repository includes unit tests for:

- View models
- Data models
- Services
- Settings-related logic

Run tests from Xcode using the `ArmoryInventoryTests` target or the configured test plan at `ArmoryInventory/ArmoryInventory.xctestplan`.

## Notes

- Data is stored locally using SwiftData.
- Backup export/import is handled as JSON from the User Data settings flow.
- Products under `ArmoryInventory/Products/` are generated build outputs and should not be treated as source.
