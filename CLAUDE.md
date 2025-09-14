# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

BRIQ is a cross-platform SwiftUI application for iOS and macOS that manages LEGO set data, including sets, parts, and minifigures. The app uses Core Data for persistent storage and loads comprehensive LEGO data from a bundled ZIP file during first launch.

## Project Structure

- **BRIQ-ios/**: iOS-specific app files and views
- **BRIQ-macos/**: macOS-specific app files, views, and platform features (menu commands, user data import/export)
- **Shared/**: Cross-platform code including models, views, and business logic
  - **CoreData/**: Core Data models and stack (Set, Part, Minifig, SetPart, SetMinifig, SetUserData)
  - **Models/**: Data model enums and utilities (Theme, PartCategory, PartColor)
  - **Models/Auto-Generated/**: Auto-generated theme and category data
  - **Views/**: Shared SwiftUI views organized by feature (Minifigs/, Parts/, SetLists/)

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

All models are defined in `Shared/CoreData/` with the data model at `Shared/CoreData/BRIQ.xcdatamodeld/BRIQ.xcdatamodel`. The Core Data stack is managed by `CoreDataStack.swift`.

### Database Initialization
- First launch loads data from bundled `init.zip` file containing comprehensive LEGO database
- Initialization happens in `ContentView.swift` using `BundledData.loadAll()`
- Progress tracking shows loading status to user
- Database reset functionality available via `Database.swift` functions

### Platform Differences
- **iOS**: Basic app structure with navigation
- **macOS**: Extended with menu commands for database management, user data import/export, view modes, and settings window

### Key Components
- `CoreDataStack`: Manages Core Data persistent container, contexts, and batch operations
- `InitializationState`: Manages app initialization state across both platforms
- `BundledData`: Handles loading and parsing of LEGO data from ZIP archive
- `Database.swift`: Database utilities including reset, import/export of user data
- `ContentView`: Main entry point handling initialization flow vs main app UI

### Theme System  
- Themes are loaded via `initThemesTree()` function in app initialization
- Auto-generated theme data in `Models/Auto-Generated/Themes.swift`
- Theme hierarchy accessible via `AllThemes` global dictionary

## Development Notes

- The app handles database corruption gracefully with automatic recreation via `CoreDataStack.resetStore()`
- User data can be preserved during database reinitialization (macOS only)
- Large dataset loading is optimized with batch operations via `CoreDataStack.performBatchInsert()`
- Core Data migrations are handled automatically with `shouldMigrateStoreAutomatically`
- Views are organized by feature area (Sets, Parts, Minifigs)
- Platform-specific code is isolated to respective app target directories