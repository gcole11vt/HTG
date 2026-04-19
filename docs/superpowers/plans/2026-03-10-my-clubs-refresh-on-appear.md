# My Clubs Refresh on Appear Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ensure the My Clubs page always shows up-to-date yardages by reloading club data every time the view appears.

**Architecture:** `ClubListView` uses a manager-based loading pattern (not @Query), so SwiftData changes made by other views (e.g., RangeManager saving a carry distance) are not automatically reflected. Adding `.onAppear` with `loadClubs()` ensures fresh data on every navigation to the page.

**Tech Stack:** SwiftUI, SwiftData, `@Observable`

---

## File Map

- **Modify:** `HTG/Features/ClubManagement/Views/ClubListView.swift`

---

### Task 1: Add .onAppear refresh to ClubListView

**Files:**
- Modify: `HTG/Features/ClubManagement/Views/ClubListView.swift:83-92`

- [ ] **Step 1: Add .onAppear to reload clubs every time the view appears**

After the existing `.task` block (line 83-92), add an `.onAppear` modifier that reloads clubs and profile data. The `.task` handles first-time initialization (creating managers, loading defaults). The `.onAppear` handles subsequent visits by refreshing data from SwiftData.

Add this immediately after the closing `}` of the `.task` block (after line 92):

```swift
.onAppear {
    Task {
        await clubManager?.loadClubs()
        await profileManager?.loadProfile()
    }
}
```

This is safe to call even on first appear — `clubManager` will be nil until `.task` completes, so the optional chaining returns early.

- [ ] **Step 2: Build and verify**

Run:
```bash
xcodebuild build -project HTG.xcodeproj -scheme HTG -sdk iphonesimulator -quiet
```
Expected: BUILD SUCCEEDED

- [ ] **Step 3: Commit**

```bash
git add HTG/Features/ClubManagement/Views/ClubListView.swift
git commit -m "fix: refresh My Clubs data on every view appearance to reflect yardage changes"
```
