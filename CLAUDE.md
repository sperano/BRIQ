# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

BRIQ is a cross-platform SwiftUI application for iOS and macOS that manages LEGO set data, including sets, parts, and minifigures. The app uses Core Data for persistent storage and loads comprehensive LEGO data from a bundled ZIP file during first launch.

## Project Structure

- **BRIQ-ios/**: iOS-specific app files and views
- **BRIQ-macos/**: macOS-specific app files, views, and platform features (menu commands, user data import/export)
- **BRIQTests/**: Unit tests (Swift Testing), hosted in the macOS app
- **Shared/**: Cross-platform code including models, views, and business logic
  - **Auto-Generated/**: Auto-generated theme, category, and color data (Themes.swift, PartCategories.swift, PartColors.swift)
  - **CoreData/**: Core Data models and stack (Set, Part, Minifig, SetPart, SetMinifig, SetUserData, PartsList, PartsListPart)
  - **SampleData/**: Sample data providers for SwiftUI previews
  - **Views/**: Shared SwiftUI views organized by feature (Minifigs/, Parts/, PartsLists/, SetDetails/, SetLists/, Settings/, Themes/)
  - Root-level utilities: Theme.swift, PartColor.swift, SetListSortOrder.swift, SetListFilters.swift (filter `@AppStorage` keys and defaults), Database.swift, BundledData.swift, DatabaseInitializer.swift, Logging.swift, PDFGenerator.swift, FocusedValues.swift

## Build Commands

This is an Xcode project. Use Xcode to build and run:
- Open `BRIQ.xcodeproj` in Xcode
- Select target (BRIQ-ios or BRIQ-macos) 
- Build: ⌘+B
- Run: ⌘+R
- Test: ⌘+U (BRIQ-macos scheme)

## Core Architecture

### Data Models (Core Data)
The app uses Core Data with these core entities:
- `Set`: LEGO sets with parts, minifigs, themes, and user data
- `Part`: Individual LEGO parts with categories and materials
- `Minifig`: LEGO minifigures
- `SetPart`/`SetMinifig`: Junction models linking sets to parts/minifigs with quantities
- `SetUserData`: User preferences per set (owned, favorite, instructions)
- `PartsList`/`PartsListPart`: User-created parts lists and their line items

All models are defined in `Shared/CoreData/` with the data model at `Shared/CoreData/BRIQ.xcdatamodeld/BRIQ.xcdatamodel`. The Core Data stack is managed by `CoreDataStack.swift`.

### Database Initialization
- First launch loads data from bundled `init.zip` file containing comprehensive LEGO database
- `ContentView.swift` triggers `DatabaseInitializer.initializeIfNeeded()`, which calls `BundledData.loadAll()`
- Progress tracking shows loading status to user
- Database reset functionality (manual reinitialization, partial-import cleanup) lives in
  `DatabaseInitializer` and `CoreDataStack.resetStore()`; `Database.swift` only handles
  user-data import/export

### Platform Differences
- **iOS**: Basic app structure with navigation
- **macOS**: Extended with menu commands for database management, user data import/export, view modes, and settings window

### Key Components
- `CoreDataStack`: Manages the Core Data persistent container, contexts, and store reset/recovery
- `DatabaseInitializer`: Owns first-launch import, failure recovery, and reinitialization
- `BundledData`: Handles loading and parsing of LEGO data from ZIP archive
- `Database.swift`: User-data import/export utilities
- `ContentView`: Main entry point handling initialization flow vs main app UI

### Theme System
- Themes are loaded via `initThemesTree()` function in app initialization
- Auto-generated theme data in `Auto-Generated/Themes.swift`
- Theme hierarchy accessible via the `AllThemes` global array (parent/children links set by `initThemesTree()`)

## Development Notes

- If the store fails to load at launch, `CoreDataStack` destroys and recreates it automatically
  (`loadStoreRecoveringFromCorruption`); `resetStore()` itself is invoked later, by
  `DatabaseInitializer`, for user-triggered reinitialization (macOS "Database > Re-Initialize")
  and to clear a partial import left behind by a crash
- User data can be preserved during database reinitialization (macOS only)
- Large dataset loading is batched in `BundledData` (`setImportBatchSize`), cooperating with task cancellation between batches
- Core Data migrations are handled automatically with `shouldMigrateStoreAutomatically`
- Views are organized by feature area (Sets, Parts, Minifigs)
- Platform-specific code mostly lives in `BRIQ-ios/`/`BRIQ-macos/`, but some shared views and utilities also branch on platform internally (`#if os(...)`)
- `Shared/` is not a target member as a whole: a new file there must be added to both targets' membership exceptions in `project.pbxproj` (Xcode's target membership checkboxes)
