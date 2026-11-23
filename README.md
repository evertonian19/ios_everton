# Everton

An iOS app for following Everton FC: fixtures, match details, squad, league table, and news, all in one place.

## Screens

| Tab | Contents |
|---|---|
| Home | Next-match countdown, standings summary, recent results, top contributors (goals + assists) |
| Fixtures | Monthly schedule with Upcoming / Results filters |
| Match Detail | Stats comparison, formation lineups, key events |
| Squad | Sortable player table → player detail (Overview · Stats · Info) |
| League | Standings, list of all 20 clubs → club info and roster → player detail |
| News | Articles translated into Korean, with a toggle to the original text |

## Design

Everton brand styling: royal blue (#003399) for the navigation bar and hero, white shadow-only cards on a light background, and blue used only as an accent. Colors and card specs live in `EvDesign/Theme.swift` and `EvDesign/Components.swift`, and use the same design tokens as the iOS menu mockup in the dashboard (`public/css/ios.css`).

## Architecture

```
App/                         App entry point
Packages/EvertonKit/
  EvCore        Models, service protocols, formatting, sample data
  EvNetworking  ESPN (default) and API-Football (optional) clients, RSS, disk cache
  EvDesign      Theme, shared components, radar chart
  EvFeatures    Screens and state management
Config/         Example API key configuration
```

## Getting Started

1. In Xcode, create a new **iOS App** project (Interface: SwiftUI, Product Name: `Everton`, minimum deployment target: iOS 18).
2. Delete the default `ContentView` and `@main` files, then add `App/EvertonApp.swift`.
3. Go to **File > Add Package Dependencies > Add Local…**, select `Packages/EvertonKit`, and link `EvFeatures` to the app target.
4. (Optional) Configure the API key:
   - Copy `Config/Secrets.example.xcconfig` to `Config/Secrets.xcconfig` and fill in your key.
   - In the project's Info > Configurations, assign this file to both Debug and Release.
   - In the app target's Info, add `API_FOOTBALL_KEY` = `$(API_FOOTBALL_KEY)`.
5. Select your signing team and run on a device.

## Data Sources

- **Default: ESPN public API** (no key required). Provides the 2026-27 fixtures, squads, standings, and match summaries (stats, lineups, key events).
- **Optional: API-Football.** Add a key and the app switches to it automatically (adds player photos and ratings).
- ESPN does not provide player ratings, photos, passing/tackling metrics, founding year, or stadium capacity. These values are never filled in with made-up data. Derived metrics (strengths, radar chart) are computed from real recorded stats such as goals, assists, shots, cards, and saves, normalized per appearance.
- Because these are unofficial APIs, responses are cached on disk, and stale cache is shown if the network request fails.

## Testing

```bash
cd Packages/EvertonKit && swift test
```
