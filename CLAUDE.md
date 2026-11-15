# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

BRIQ is a cross-platform SwiftUI application for iOS and macOS that manages LEGO set data, including sets, parts, and minifigures. The app uses Core Data for persistent storage and loads comprehensive LEGO data from a bundled ZIP file during first launch.

## Project Structure

- **BRIQ-ios/**: iOS-specific app files and views
- **BRIQ-macos/**: macOS-specific app files, views, and platform features (menu commands, user data import/export)
- **Shared/**: Cross-platform code including models, views, and business logic
  - **Auto-Generated/**: Auto-generated theme, category, and color data (Themes.swift, PartCategories.swift, PartColors.swift)
  - **CoreData/**: Core Data models and stack (Set, Part, Minifig, SetPart, SetMinifig, SetUserData)
  - **SampleData/**: Sample data providers for SwiftUI previews
  - **Views/**: Shared SwiftUI views organized by feature (Minifigs/, Parts/, SetDetails/, SetLists/, Themes/)
  - Root-level utilities: Theme.swift, PartColor.swift, EnvironmentKeys.swift, SetListSortOrder.swift, Database.swift, BundledData.swift, InitializationState.swift

## Build Commands

This is an Xcode project. Use Xcode to build and run:
- Open `BRIQ.xcodeproj` in Xcode
- Select target (BRIQ-ios or BRIQ-macos) 
- Build: ⌘+B
- Run: ⌘+R

## Core Architecture

### Data Models (Core Data)
The app uses Core Data with these core entities:
- `Set`: LEGO sets with parts, minifigs, themes, and user data
- `Part`: Individual LEGO parts with categories and materials
- `Minifig`: LEGO minifigures
- `SetPart`/`SetMinifig`: Junction models linking sets to parts/minifigs with quantities
- `SetUserData`: User preferences per set (owned, favorite, instructions)

All models are defined in `Shared/CoreData/` with the versioned data model at `Shared/CoreData/BRIQ.xcdatamodeld` (current version: `BRIQ 2.xcdatamodel`, named in `.xccurrentversion`). The Core Data stack is managed by `CoreDataStack.swift`.

The identity attributes behind each `Identifiable.id` carry uniqueness constraints: `number` on `Set`, `SetUserData`, `Part` and `Minifig`, `name` on `PartsList`.

### Database Initialization
- First launch loads data from bundled `init.zip` file containing comprehensive LEGO database
- Initialization happens in `DatabaseInitializer.swift` (started from `ContentView`) using `BundledData.loadAll(from:into:progress:)`
- Progress tracking shows loading status to user
- Database reset: `DatabaseInitializer.reinitialize(preserveUserData:)` wipes the store with `CoreDataStack.resetStore()` and reloads it

### Platform Differences
- **iOS**: Basic app structure with navigation
- **macOS**: Extended with menu commands for database management, user data import/export, view modes, and settings window

### Key Components
- `CoreDataStack`: Manages Core Data persistent container, contexts, and batch operations
- `InitializationState`: Manages app initialization state across both platforms
- `BundledData`: Handles loading and parsing of LEGO data from ZIP archive
- `Database.swift`: Typed (`Codable`) user-data export and import; import validates the whole file before changing anything, throws `UserDataImportError` for invalid input and rethrows the Core Data error when the save fails
- `ContentView`: Main entry point handling initialization flow vs main app UI

### Theme System
- Themes are loaded via `initThemesTree()` function in app initialization
- Auto-generated theme data in `Auto-Generated/Themes.swift`
- Theme hierarchy accessible via `AllThemes` global dictionary

## Development Notes

- The app handles database corruption gracefully with automatic recreation in `CoreDataStack.loadStoreRecoveringFromCorruption`
- User data can be preserved during database reinitialization (macOS only): it is checked to import again before the wipe, and kept in `UserDefaults` until the reloaded store has it back
- Large dataset loading is optimized with batch operations via `CoreDataStack.performBatchInsert()`
- Core Data migrations are lightweight (`shouldMigrateStoreAutomatically`). A model change needs a new model version, never an in-place edit: migration needs the old version to read the store. Before migrating, `StoreDeduplicator` resolves rows that would violate the uniqueness constraints, since a failed migration recreates the store
- Views are organized by feature area (Sets, Parts, Minifigs)
- Platform-specific code is isolated to respective app target directories