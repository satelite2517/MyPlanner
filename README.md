# Planner

SwiftUI + SwiftData based planner app for weekly, monthly, and list-focused task management.

## Why This Exists

Planner started from a simple question:

Why do so many productivity apps fail to clearly separate a real deadline from the work that must be done before that deadline?

This app is built around that distinction.

- A `Deadline` is the actual due date or end condition.
- A `Todo` is the work you need to do on a specific day.

That matters because:

- A single piece of work can take more than one day.
- A deadline and the tasks required to reach it are not the same thing.
- Mixing them together makes planning harder, not easier.

Planner is designed to show those two concepts separately while still letting them relate to each other.

## What It Does

- Weekly view with per-day cards
- Monthly calendar with inline selected-day details
- List view filtered from the current week's Monday onward
- Separate `Todo` and `Deadline` models
- Linked planning model where deadlines and day-specific work can coexist without being conflated
- Manual item creation for both todos and deadlines
- Theme customization
  - Accent color
  - Background color
- Korean / English language switching
- Reminders import
  - Imported reminders are stored as `Deadline` items
  - App can sync reminders automatically on launch
  - Manual sync is also available in `Me`

## Tech Stack

- SwiftUI
- SwiftData
- EventKit

## Project Structure

- `Planner/`
  - App source
- `Planner.xcodeproj/`
  - Xcode project
- `PlannerTests/`
  - Unit tests
- `PlannerUITests/`
  - UI tests
- `front/`
  - Separate frontend assets/prototype workspace

## Running The App

1. Open `Planner.xcodeproj` in Xcode.
2. Select the `Planner` scheme.
3. Run on:
   - iPhone simulator / device
   - macOS target

## iPhone Signing

If Xcode shows:

`Signing for "Planner" requires a development team`

set your Apple team in:

`Target > Signing & Capabilities > Team`

You may also need a unique bundle identifier for your account.

## Reminders Access

The app uses EventKit to import Apple Reminders.

- On iOS, allow Reminders access when prompted.
- On macOS, allow both:
  - `Reminders`
  - `Calendars`

This is required because EventKit reminder access on macOS goes through Calendar services as well.

## Current Notes

- Weekly day detail popup uses tabbed `Todos / Deadlines` sections.
- macOS weekly day cards use a split `Todo | Deadline` layout.
- Monthly day selection shows details inline below the calendar instead of opening a popup.
