# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

# HTG Project Guide: The Lean Rebuild (2026)

## Project Overview
HTG is a high-performance, lean iOS application built from the ground up to replace a legacy prototype. It focuses on clean architecture, Swift 6 safety, and modern SwiftUI patterns.

## Tech Stack & Standards
- **Language:** Swift 6 (Strict Concurrency enabled)
- **UI Framework:** SwiftUI (Liquid Glass design compatible)
- **Minimum Target:** iOS 18.0+
- **Data Persistence:** SwiftData (Macro-based, `@Model`)
- **Architecture:** MVVM + Service Pattern
- **State Management:** `@Observable` macro (Avoid `ObservableObject` / `Published`)

## File Structure
- `App/`: Entry point (`HTGApp.swift`) and global configuration.
- `Features/`: Feature-based modules (e.g., `Features/Dashboard/`). Each contains its own Views and ViewModels.
- `Core/Models/`: SwiftData entity definitions.
- `Core/Services/`: Logic-heavy workers (Network, Database, Auth).
- `UIComponents/`: Reusable, atomic design elements and styling.
- `Resources/`: Assets and localizable strings.

## Code Style Guidelines
- **Modern Concurrency:** Use `async/await` and `@MainActor` exclusively. No completion handlers.
- **Naming:** Verbose, descriptive naming (e.g., `NetWorthCalculationService`).
- **Composition:** Views must be broken into small, sub-view components or `private var` extensions if they exceed 30 lines.
- **Service Isolation:** Views and ViewModels must never interact with SwiftData directly; use a `Service` layer.
- **Logic Placement:** Keep ViewModels focused on UI state; move complex math/logic to dedicated Services.

## Test-Driven Development (TDD) Workflow
This project follows a strict TDD "Red-Green-Refactor" cycle:
1. **Tests First:** Write unit tests for new logic before implementation.
2. **Verification:** Run the `TDD Runner` command to confirm failure.
3. **Implementation:** Write the minimal code needed to pass the tests.
4. **Refactor:** Clean the code without changing the tests.
*Note: Do not mock functionality that doesn't exist; use the tests to define the API.*

## Build & Test Commands
- **Build:** `xcodebuild -project HTG.xcodeproj -scheme HTG -sdk iphonesimulator`
- **Clean Build:** `xcodebuild clean build -project HTG.xcodeproj -scheme HTG -sdk iphonesimulator`
- **TDD Runner (Unit Tests):** `xcodebuild test -project HTG.xcodeproj -scheme HTG -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -only-testing HTGTests`
- **Full Test Suite:** `xcodebuild test -project HTG.xcodeproj -scheme HTG -destination 'platform=iOS Simulator,name=iPhone 16 Pro'`
- **Lint:** `swiftlint`
