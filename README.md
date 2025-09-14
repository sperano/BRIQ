# BRIQ

A cross-platform SwiftUI application for iOS and macOS that manages LEGO set data, including sets, parts, and minifigures.

## Features

- **Comprehensive LEGO Database**: Browse and manage LEGO sets, parts, and minifigures
- **Cross-Platform**: Native apps for both iOS and macOS with platform-specific features
- **User Data Management**: Track owned sets, favorites, and instruction availability
- **Database Import/Export**: Backup and restore user data (macOS)
- **Theme Organization**: Browse sets by LEGO themes with hierarchical organization

## Requirements

- **iOS**: iOS 14.0+
- **macOS**: macOS 11.0+
- **Xcode**: 12.0+ for building from source

## Installation

### Building from Source

1. Clone the repository
2. Open `BRIQ.xcodeproj` in Xcode
3. Select your target platform (BRIQ-ios or BRIQ-macos)
4. Build and run (⌘+B to build, ⌘+R to run)

### First Launch

On first launch, the app will initialize its database by loading comprehensive LEGO data from a bundled archive. This process may take a few moments and progress will be displayed.

## Architecture

### Core Data Models

- **Set**: LEGO sets with associated parts, minifigures, and themes
- **Part**: Individual LEGO parts with categories and color information
- **Minifig**: LEGO minifigures
- **SetPart/SetMinifig**: Junction models linking sets to parts/minifigs with quantities
- **SetUserData**: User preferences per set (owned status, favorites, instructions)

### Project Structure

```
BRIQ/
├── BRIQ-ios/           # iOS-specific app files and views
├── BRIQ-macos/         # macOS-specific app files and platform features
└── Shared/             # Cross-platform code
    ├── CoreData/       # Core Data models and stack
    ├── Models/         # Data models and utilities
    └── Views/          # SwiftUI views organized by feature
```

## Platform Differences

### iOS
- Basic navigation and browsing interface
- Core set, part, and minifigure management

### macOS
- Extended menu commands for database management
- User data import/export functionality
- Multiple view modes and settings window
- Enhanced navigation and window management

## Database Management

- **Automatic Initialization**: Database is populated on first launch from bundled data
- **Corruption Recovery**: Automatic database recreation with error handling
- **User Data Preservation**: User preferences can be preserved during database resets (macOS)
- **Import/Export**: Backup and restore user data via JSON format (macOS)

## Development

The app uses modern SwiftUI patterns with Core Data for persistence. Key components include:

- `CoreDataStack`: Manages Core Data operations and batch processing
- `BundledData`: Handles initial data loading from ZIP archive
- `Database.swift`: Utilities for database management and user data operations
- `InitializationState`: Manages app startup and initialization flow

## Contributing

This is a personal project for managing LEGO collections. The codebase demonstrates SwiftUI best practices, Core Data integration, and cross-platform iOS/macOS development patterns.

## License

[Add your license information here]
