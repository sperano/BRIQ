# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

BRIQ is a cross-platform SwiftUI application for iOS and macOS that manages LEGO set data, including sets, parts, and minifigures. The app uses SwiftData for persistent storage and loads comprehensive LEGO data from a bundled ZIP file during first launch.

## Project Structure

- **BRIQ-ios/**: iOS-specific app files and views
- **BRIQ-macos/**: macOS-specific app files, views, and platform features (menu commands, user data import/export)
- **Shared/**: Cross-platform code including models, views, and business logic
  - **Models/**: SwiftData models for Set, Part, Minifig, SetPart, SetMinifig, SetUserData
  - **Models/Auto-Generated/**: Auto-generated theme and category data
  - **Views/**: Shared SwiftUI views organized by feature (Minifigs/, Parts/, SetLists/)

## Build Commands

This is an Xcode project. Use Xcode to build and run:
- Open `BRIQ.xcodeproj` in Xcode
- Select target (BRIQ-ios or BRIQ-macos) 
- Build: ⌘+B
- Run: ⌘+R

## Core Architecture

### Data Models (SwiftData)
The app uses SwiftData with these core models:
- `Set`: LEGO sets with parts, minifigs, themes, and user data
- `Part`: Individual LEGO parts with categories and colors  
- `Minifig`: LEGO minifigures
- `SetPart`/`SetMinifig`: Junction models linking sets to parts/minifigs with quantities
- `SetUserData`: User preferences per set (owned, favorite, instructions)

All models are defined in `Shared/Models/` and registered in both app entry points.

### Database Initialization
- First launch loads data from bundled `init.zip` file containing comprehensive LEGO database
- Initialization happens in `ContentView.swift` using `BundledData.loadAll()`
- Progress tracking shows loading status to user
- Database reset functionality available via `Database.swift` functions

### Platform Differences
- **iOS**: Basic app structure with navigation
- **macOS**: Extended with menu commands for database management, user data import/export, view modes, and settings window

### Key Components
- `InitializationState`: Manages app initialization state across both platforms
- `BundledData`: Handles loading and parsing of LEGO data from ZIP archive
- `Database.swift`: Database utilities including reset, import/export of user data
- `ContentView`: Main entry point handling initialization flow vs main app UI

### Theme System  
- Themes are loaded via `initThemesTree()` function in app initialization
- Auto-generated theme data in `Models/Auto-Generated/Themes.swift`
- Theme hierarchy accessible via `AllThemes` global dictionary

## Development Notes

- The app handles database corruption gracefully with automatic recreation
- User data can be preserved during database reinitialization (macOS only)
- Large dataset loading is optimized with batching and background contexts
- Views are organized by feature area (Sets, Parts, Minifigs)
- Platform-specific code is isolated to respective app target directories