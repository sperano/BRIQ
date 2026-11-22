# AGENTS.md

This file provides guidance to Codex (Codex.ai/code) when working with code in this repository.

## Project Overview

BRIQ is a cross-platform SwiftUI application for iOS and macOS that manages LEGO set data, including sets, parts, and minifigures. The app uses Core Data for persistent storage and loads comprehensive LEGO data from a bundled ZIP file during first launch.

## Project Structure

- **BRIQ-ios/**: iOS-specific app files and views
- **BRIQ-macos/**: macOS-specific app files, views, and platform features (menu commands, user data import/export)
- **BRIQKit/**: Local Swift package, a dependency of both app targets, holding the code that imports no Apple-only framework; it builds and tests on Linux (`swift test --package-path BRIQKit`). Declare `public` only what the app uses
  - **Sources/BRIQKit/Auto-Generated/**: Auto-generated theme, category, and color data (Themes.swift, PartCategories.swift, PartColors.swift)
  - Theme.swift (the theme tree), PartColor.swift (color data), RGBColor.swift (hex parsing, luminance), SetNumber.swift (set-number sort key), BundledArchive.swift (the `init.zip` format: the `JSON*` types and unzip + decode)
  - **Tests/BRIQKitTests/**: its unit tests (Swift Testing)
- **BRIQTests/**: Unit tests (Swift Testing), hosted in the macOS app
- **Shared/**: Cross-platform code including models, views, and business logic
  - **CoreData/**: Core Data models and stack (Set, Part, Minifig, SetPart, SetMinifig, SetUserData, PartsList, PartsListPart)
  - **SampleData/**: Sample data providers for SwiftUI previews
  - **Views/**: Shared SwiftUI views organized by feature (Minifigs/, Parts/, PartsLists/, SetDetails/, SetLists/, Settings/, Themes/)
  - Root-level utilities: PartColor.swift (`swiftUIColor`, `lookup(id:)`), SetListSortOrder.swift, SetListFilters.swift (filter `@AppStorage` keys and defaults), Database.swift, BundledData.swift, DatabaseInitializer.swift, Logging.swift, PDFGenerator.swift, ImageLoader.swift, ConcurrentMap.swift, IconSize.swift, FocusedValues.swift, ImageZoom.swift (zoom levels of the iOS full-size image viewer)
  - **Localizable.xcstrings**: String Catalog of both apps (source language English)

## Build Commands

This is an Xcode project. Use Xcode to build and run:
- Open `BRIQ.xcodeproj` in Xcode
- Select target (BRIQ-ios or BRIQ-macos) 
- Build: ⌘+B
- Run: ⌘+R
- Test: ⌘+U (BRIQ-macos scheme)

Lint and format, on macOS or Linux (SwiftFormat and SwiftLint on `PATH`; `brew install swiftformat swiftlint` on macOS):
- `make lint`: SwiftFormat in check mode (`.swiftformat`), then SwiftLint `--strict` (`.swiftlint.yml`); fails on any finding
- `make format`: rewrites what SwiftFormat can fix, then runs SwiftLint
- `BRIQKit/Sources/BRIQKit/Auto-Generated/` (written by briq-utils) is excluded from both. Fix findings in the code, never with an inline `swiftlint:disable`/`swiftformat:disable` comment; a rule that does not fit the code is turned off in the config with a comment saying why
- SwiftFormat drops a redundant `return`, so a computed property whose body would then start with `set.` parses as a setter: SwiftLint reports it as `unused_setter_value`. Write such a body as an `if` expression, or use the `Set`'s property directly

## Core Architecture

### Data Models (Core Data)
The app uses Core Data with these core entities:
- `Set`: LEGO sets with parts, minifigs, themes, and user data
- `Part`: Individual LEGO parts with categories and materials
- `Minifig`: LEGO minifigures
- `SetPart`/`SetMinifig`: Junction models linking sets to parts/minifigs with quantities
- `SetUserData`: User preferences per set (owned, favorite, instructions)
- `PartsList`/`PartsListPart`: User-created parts lists and their line items

All models are defined in `Shared/CoreData/` with the versioned data model at `Shared/CoreData/BRIQ.xcdatamodeld` (current version: `BRIQ 2.xcdatamodel`, named in `.xccurrentversion`). The Core Data stack is managed by `CoreDataStack.swift`.

The identity attributes behind each `Identifiable.id` carry uniqueness constraints: `number` on `Set`, `SetUserData`, `Part` and `Minifig`, `name` on `PartsList`.

### Database Initialization
- `Resources/init.zip` is stored in Git LFS: `git lfs install` before cloning, otherwise the checkout gets a 133-byte pointer instead of the zip and the first-launch import fails
- First launch loads data from bundled `init.zip` file containing comprehensive LEGO database
- `ContentView.swift` triggers `DatabaseInitializer.initializeIfNeeded()`, which calls `BundledData.loadAll(from:into:progress:)`
- Progress tracking shows loading status to user
- Database reset: `DatabaseInitializer.reinitialize(preserveUserData:)` wipes the store with `CoreDataStack.resetStore()` and reloads it; `DatabaseInitializer` also uses `resetStore()` to clear a partial import. `Database.swift` only handles user-data import/export

### Platform Differences
- **iOS**: Basic app structure with navigation
- **macOS**: Extended with menu commands for database management, user data import/export, view modes, and settings window

### Key Components
- `CoreDataStack`: Manages the Core Data persistent container, contexts, and store reset/recovery
- `DatabaseInitializer`: Owns first-launch import, failure recovery, and reinitialization
- `BundledArchive` (BRIQKit): unzips `init.zip` and decodes it into `JSONData`
- `BundledData`: imports the decoded `JSONData` into Core Data
- `Database.swift`: Typed (`Codable`) user-data export and import; import validates the whole file before changing anything, throws `UserDataImportError` for invalid input and rethrows the Core Data error when the save fails
- `ContentView`: Main entry point handling initialization flow vs main app UI
- `ImageLoader` / `ThumbnailImage`: remote images, decoded at the size they are drawn and cached in memory; URLs that can never load (an HTTP 4xx other than 408 and 429, a bad or unsupported URL, data that is not an image) are not requested again until Retry (only `IconImage` shows one; rows and set icons try again after a relaunch); network errors, 5xx, 408 and 429 are retried on the next appearance. Use `ThumbnailImage` rather than `AsyncImage` for grids and rows
- `SetContentTotals`: status-bar minifig and part totals, summed by the store (`SUM(quantity)`) instead of faulting each set's relationships
- `PDFGenerator`: Async generator for exporting parts lists as PDF with grid layout
- `FocusedValues`: SwiftUI focused values for menu command integration

### Theme System
- Themes are loaded via `initThemesTree()` function in app initialization
- Auto-generated theme data in `BRIQKit/Sources/BRIQKit/Auto-Generated/Themes.swift`
- Theme hierarchy accessible via the `AllThemes` global array (parent/children links set by `initThemesTree()`)

### Parts Lists Feature
- Users can create custom parts lists to track parts they need
- Parts can be added from set detail views with specific colors and quantities
- PDF export generates a grid of part images for printing (useful for cutting out reference cards)
- PDF options include configurable column count (6-20, default 14)
- Uses `focusedSceneValue` to enable menu command access (File → Export Parts List as PDF, ⇧⌘E)

## Development Notes

- If the store fails to load at launch, `CoreDataStack` destroys and recreates it automatically
  (`loadStoreRecoveringFromCorruption`); `resetStore()` itself is invoked later, by
  `DatabaseInitializer`, for user-triggered reinitialization (macOS "Database > Re-Initialize")
  and to clear a partial import left behind by a crash
- User data can be preserved during database reinitialization (macOS only): it is checked to import again before the wipe, and kept in `UserDefaults` until the reloaded store has it back (a failed or interrupted restore is retried on the next launch, and before a later re-initialize exports again)
- Large dataset loading is batched in `BundledData` (`setImportBatchSize`), cooperating with task cancellation between batches
- Core Data migrations are lightweight (`shouldMigrateStoreAutomatically`). A model change needs a new model version, never an in-place edit: migration needs the old version to read the store. Before migrating, `StoreDeduplicator` resolves rows that would violate the uniqueness constraints, since a failed migration recreates the store
- Views are organized by feature area (Sets, Parts, Minifigs)
- User-facing text is localized through `Shared/Localizable.xcstrings`. String literals passed to SwiftUI (`Text`, `Button`, `Label`, `Toggle`, `.navigationTitle`, ...) are `LocalizedStringKey`s and localized as is; a title passed through a property or parameter must be typed `LocalizedStringKey` too, and text built in code (enum display names, error descriptions, alerts) uses `String(localized:)`. A ternary of literals (`cond ? "A" : "B"`) is a `String`, which SwiftUI shows verbatim: wrap each branch in `Text(...)` or `String(localized:)`. A string with a count gets plural variants in the catalog instead of `count == 1 ? ... : ...`; Xcode adds the other keys to the catalog when it builds. Data names (sets, themes, colors, part categories) are not localized
- Icon-only controls carry a text label (`Label` in toolbars, `.accessibilityLabel` elsewhere) and decorative images are `.accessibilityHidden`; `StarRatingView` is a single VoiceOver element named by its `label`, adjustable only when `isInteractive`
- Platform-specific code mostly lives in `BRIQ-ios/`/`BRIQ-macos/`, but some shared views and utilities also branch on platform internally (`#if os(...)`)
- Unit tests (Swift Testing) live in `BRIQTests/` (the `BRIQTests` target, hosted in the macOS app); they need Xcode to build and run
- `Shared/` and `Resources/` are synchronized folders of both app targets: a new file there is in both apps without touching `project.pbxproj`. A platform-only file goes in the other target's membership exceptions for the folder (unchecking that target's membership box in Xcode); the macOS-only `Shared/` files are listed in the `BRIQ-ios` exception set
