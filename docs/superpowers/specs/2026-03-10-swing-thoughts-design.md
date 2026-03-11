# Swing Thoughts, Pre-Shot Routine & Mantra — Design Spec

## Overview

Add three mental-game features that display in Golf Mode during shot preparation: a Pre-Shot Routine (ordered checklist), a Mantra (single phrase), and Swing Thoughts (tagged to clubs, shot types, or "All"). All are managed in the Profile section, with Swing Thoughts also addable from Club Detail pages.

## Data Models

### PreShotRoutineItem (new SwiftData model)
- `id: UUID`
- `text: String`
- `sortOrder: Int`
- `@Relationship(inverse:) var profile: UserProfile?`

### SwingThought (new SwiftData model)
- `id: UUID`
- `text: String`
- `tagType: String` — "all", "club", or "shotType"
- `tagValue: String` — empty for "all", club name for "club", shot type name for "shotType"
- `@Relationship(inverse:) var profile: UserProfile?`

### UserProfile additions
- `mantra: String` (default: "Trust your swing")
- `showPreShotRoutine: Bool` (default: true)
- `showMantra: Bool` (default: true)
- `@Relationship(deleteRule: .cascade) var preShotRoutineItems: [PreShotRoutineItem]`
- `@Relationship(deleteRule: .cascade) var swingThoughts: [SwingThought]`

### Default data (seeded on first profile creation)
- Pre-Shot Routine: "Pick target", "Visualize shot", "One practice swing", "Commit"
- Mantra: "Trust your swing"

## Profile UI — Input & Management

### Pre-Shot Routine section
- Toggle: "Show in Golf Mode" (bound to `showPreShotRoutine`)
- Ordered list of items with swipe-to-delete and drag-to-reorder
- Inline text editing
- "Add Step" button

### Mantra section
- Toggle: "Show in Golf Mode" (bound to `showMantra`)
- Single editable text field

### Swing Thoughts section
- List of all swing thoughts displaying text + tag (e.g., "Swing Fast — Driver")
- Swipe-to-delete
- "Add Swing Thought" button opens form with:
  - Text field for the thought
  - Picker for tag type: All / Club / Shot Type
  - Conditional picker for specific club name or shot type name

### Club Detail page addition
- New "Swing Thoughts" section at bottom
- Shows thoughts tagged to that club
- "Add Swing Thought" button pre-fills tag to that club name

## Golf Mode Display

In the left column of YardageBookPageView, below ShotInfoHeaderView and ResetIndicatorView, in this order:

1. **Pre-Shot Routine** (if `showPreShotRoutine` is true)
   - Header: "Pre-Shot Routine" in JournalTheme.handwritten
   - Numbered list of steps, compact, muted color

2. **Mantra** (if `showMantra` is true)
   - No header — just the text
   - Italic, JournalTheme.handwritten, slightly larger than routine text

3. **Swing Thoughts** (if any match the current club/shot)
   - A thought matches if: tagType is "all", OR tagValue matches displayedClubShot.clubName, OR tagValue matches displayedClubShot.shotTypeName
   - All matching thoughts shown stacked
   - Small header "Swing Thoughts" with each thought as a bullet
   - JournalTheme.handwritten styling

The GolfModeViewModel resolves matching swing thoughts based on displayedClubShot.clubName and displayedClubShot.shotTypeName.
