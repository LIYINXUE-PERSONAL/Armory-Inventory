# Magazine Patterns Audit

This document captures the current magazine compatibility behavior before the pattern refactor starts. It exists to satisfy issue `#18` and to give issues `#19` through `#23` a shared baseline.

## Current Model

- `Magazine` stores compatibility as two direct relationships: optional `caliber` and optional `firearm` ([ArmoryInventory/Accessories/Magazines/MagazineModels.swift](/Users/liyinxue/.codex/worktrees/283c/ArmoryInventory/ArmoryInventory/Accessories/Magazines/MagazineModels.swift:12)).
- `Firearm` stores linked magazines through the inverse relationship `magazines`, but does not define any magazine-specific compatibility rules beyond owning that relationship ([ArmoryInventory/Firearms/FirearmModels.swift](/Users/liyinxue/.codex/worktrees/283c/ArmoryInventory/ArmoryInventory/Firearms/FirearmModels.swift:135)).
- There is no canonical identifier for a magazine family or pattern. Compatibility is currently inferred from free-form brand/model text plus optional caliber and firearm links.

## Active Compatibility Paths

### 1. Manual magazine creation and editing

- `AddMagazineView` exposes a `Caliber` picker and persists the selected caliber directly on the `Magazine` record.
- `AddMagazineViewModel.addMagazine(...)` and `updateMagazine(...)` write the relationship without validating whether the selected caliber matches the linked firearm or any broader magazine family ([ArmoryInventory/Accessories/Magazines/AddMagazineViewModel.swift](/Users/liyinxue/.codex/worktrees/283c/ArmoryInventory/ArmoryInventory/Accessories/Magazines/AddMagazineViewModel.swift:121)).
- Editing an existing magazine can also unlink the firearm independently of caliber, which means caliber and firearm can drift apart over time.

### 2. Firearm editor magazine linking

- `AddFirearmViewModel.availableMagazines(...)` is the only reusable filter that gates what a firearm can link.
- That filter only checks whether a magazine is already linked to a different firearm. It does not check caliber, firearm type, action, capacity family, or brand/model pattern ([ArmoryInventory/Firearms/AddFirearmViewModel.swift](/Users/liyinxue/.codex/worktrees/283c/ArmoryInventory/ArmoryInventory/Firearms/AddFirearmViewModel.swift:138)).
- `AddFirearmView` surfaces each magazine's stored caliber in the UI, but that value is informational only. The user can still select any unassigned magazine ([ArmoryInventory/Firearms/AddFirearmView.swift](/Users/liyinxue/.codex/worktrees/283c/ArmoryInventory/ArmoryInventory/Firearms/AddFirearmView.swift:271), [ArmoryInventory/Firearms/AddFirearmView.swift](/Users/liyinxue/.codex/worktrees/283c/ArmoryInventory/ArmoryInventory/Firearms/AddFirearmView.swift:478)).

### 3. Persistence, export, and import

- `UserDataTransferService` exports magazine compatibility as raw `caliberName` plus `firearmID`, preserving the current record-level model rather than a normalized pattern identifier ([ArmoryInventory/Services/UserDataTransferService.swift](/Users/liyinxue/.codex/worktrees/283c/ArmoryInventory/ArmoryInventory/Services/UserDataTransferService.swift:168)).
- Because compatibility is serialized as direct links, migration work in issue `#20` must preserve unknown or legacy combinations without data loss.

## Duplicate Rules And Gaps

| Area | Current behavior | Problem | Follow-up |
| --- | --- | --- | --- |
| Ownership of compatibility | `Magazine` owns optional `caliber` and optional `firearm` | Compatibility is represented as ad hoc links on each record instead of a shared pattern definition | `#19`, `#20` |
| Firearm-link validation | `AddFirearmViewModel.availableMagazines(...)` blocks only magazines linked to another firearm | Same-firearm exclusivity is enforced, but caliber and platform compatibility are not | `#21`, `#22` |
| Magazine editor validation | `AddMagazineViewModel.canAdd(...)` validates required fields and color detail only | A user can save combinations that conflict with the linked firearm because no compatibility check runs here | `#21` |
| UI messaging | Magazine linking screens display stored caliber text only | The UI implies compatibility information exists, but it is not used to drive selection | `#22` |
| Backup schema | Export/import stores raw caliber and firearm references | Migration needs a legacy fallback path because existing backups cannot resolve a future pattern id by themselves | `#19`, `#20` |
| Test coverage | Tests assert relationship persistence and list filtering | There is no dedicated test suite for compatibility rules because there is no centralized rule engine yet | `#23` |

## Refactor Constraints

- Unknown and legacy magazine records must remain round-trippable through backup import/export.
- The first normalized type should model pattern identity separately from item-specific state such as count, color, notes, and purchase data.
- Compatibility checks need one shared entry point that both the magazine editor and firearm editor can call.
- UI changes should consume compatibility results from that shared entry point instead of duplicating ad hoc filters.

## Recommended Sequence

1. Introduce a canonical `MagazinePattern` type with explicit compatibility constraints and an unknown or legacy fallback (`#19`).
2. Add migration logic from existing magazine records into that pattern model, keeping original values safe for unresolved cases (`#20`).
3. Move all firearm-to-magazine compatibility decisions into one validator used by add/edit flows and linking flows (`#21`).
4. Update picker and detail UI to explain why a magazine is compatible, incompatible, or legacy (`#22`).
5. Add tests around mapping, validation, fallback handling, and UI-facing compatibility outcomes (`#23`).
