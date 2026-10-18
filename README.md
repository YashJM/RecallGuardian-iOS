# RecallGuardian — iOS

SwiftUI app for Canada's safety recalls. Opens to the same ranked feed as the
web app; the **Guardian** (v2) will watch for recalls on what your household
owns, entirely on-device.

> Built on the Government of Canada
> [Recalls and Safety Alerts](https://recalls-rappels.canada.ca) open feed
> (CFIA · Health Canada · Transport Canada).

## Project is source-only

These files were scaffolded without Xcode, so there's no `.xcodeproj` yet.
To get a running app:

1. Open **Xcode → New → App**. Product name `RecallGuardian`, interface
   **SwiftUI**, language **Swift**, min deployment **iOS 17** (needed for
   `@Observable`).
2. Delete the default `ContentView.swift` and the generated `App` file.
3. Drag the `RecallGuardian/` source folder (Models, Services, Views, Theme,
   `RecallGuardianApp.swift`) into the project ("Copy items if needed" off —
   they're already here).
4. **App Transport Security** is fine: the feed is HTTPS.
5. Build & run.

## App ID & capabilities

**Bundle ID: `ca.recallguardian.app`** (permanent — don't change it after shipping).

Register via Xcode (easiest): set the Bundle ID in *Signing & Capabilities*, sign
in with your Apple ID, turn on *Automatically manage signing*, and add capabilities
— Xcode registers the App ID on the portal for you.

Capabilities, by phase (all editable later):

| Capability | When | Notes |
| --- | --- | --- |
| **Background Modes → Background fetch** | V2 (now) | Lets the Guardian check for new recalls in the background. Writes `UIBackgroundModes`. |
| **Push Notifications** | V2.1 | Only if you add APNs for lower-latency alerts. Create an **APNs Auth Key** (.p8) under *Keys* for the sender. The app delegate already has the token hooks stubbed. |
| **App Groups** (`group.ca.recallguardian.app`) | V2/V3 | Share the watchlist with a home-screen widget. Move `Watchlist`/`BackgroundRefresh` storage from `UserDefaults.standard` to the group container. |
| **Associated Domains** (`applinks:recallguardian.ca`) | V3 | Universal Links. Host `AppSiteAssociation/apple-app-site-association` at `https://recallguardian.ca/.well-known/` and replace `TEAMID` with your Team ID. |

Info.plist keys to add (Target → *Info*, or your `Info.plist`):

```xml
<key>BGTaskSchedulerPermittedIdentifiers</key>
<array><string>ca.recallguardian.app.refresh</string></array>
<key>NSCameraUsageDescription</key>
<string>Scan a product barcode to add it to your Guardian watchlist.</string>
```
(`UIBackgroundModes` → `fetch` is written when you enable the Background fetch capability.)

## V2 — the Guardian (on-device, no backend)

Already implemented in source:

- `Models/Watchlist.swift` — the household watchlist (brands + categories), stored on-device.
- `Services/WatchMatcher.swift` — pure local matching of recalls to the watchlist.
- `Services/NotificationManager.swift` — permission + local notifications (time-sensitive for critical).
- `Services/BackgroundRefresh.swift` — `BGTaskScheduler` job: fetch → match → notify new matches (tracks seen NIDs so it never re-alerts the backlog).
- `AppDelegate.swift` — registers the background task, presents foreground alerts, stubs APNs token hooks.
- `Views/GuardianView.swift` — add brands, toggle categories, turn on alerts, see current matches.

The whole V2 loop runs with **no server**: the public feed is matched on the phone,
and the watchlist never leaves the device. APNs (V2.1) is optional and only improves
delivery latency.

## Source layout

```
RecallGuardian/
├── RecallGuardianApp.swift   App entry + tab bar + scene-phase scheduling
├── AppDelegate.swift         Background task registration + notification delegate
├── Models/
│   ├── Recall.swift          Recall, RawRecall (feed decoding), Tier, Group
│   └── Watchlist.swift       On-device watchlist (brands + categories)
├── Services/
│   ├── RecallClassifier.swift  Grouping + severity + ranking  ← shared contract
│   ├── RecallStore.swift       Fetch, decode, normalize, rank (@Observable)
│   ├── WatchMatcher.swift      Pure local recall ↔ watchlist matching
│   ├── NotificationManager.swift  Permission + local notifications
│   └── BackgroundRefresh.swift    BGTaskScheduler: fetch → match → notify
├── Views/
│   ├── FeedView.swift          Ranked feed + category filter
│   ├── RecallRow.swift         The recall card (severity stripe)
│   ├── RecallDetailView.swift  Full recall + official source link
│   └── GuardianView.swift      Watchlist + alerts + current matches
└── Theme/
    └── Theme.swift           Colour tokens mirroring the web globals.css
```

## Shared with the web app

`RecallClassifier.swift` is a line-for-line port of the web app's
`src/lib/recalls.ts`: the same seven household groups, the same severity tiers,
and the same ranking score —

```
score = category (Critical 3 · High 2 · Standard 1)
      × class    (Type I 1.5 · Type II 1.2 · Type III 1.0 · none 1.1)
      × recency  (≤30d 1.4 · ≤90d 1.2 · ≤1y 1.0 · older 0.7)
```

Keep the two in sync, or the website and the app will disagree about what's
important. The web source lives at `github.com/YashJM/RecallGuardian`.

## Fonts (optional polish)

`Theme.swift` currently uses the system font. To match the web app exactly, add
**Archivo** (display) and **Newsreader** (body) to the target and point
`Font.display(_:_:)` at them.

## Roadmap

- **V1 (now):** ranked feed, category filters, official source on every recall.
- **V2:** the Guardian — on-device household profile + brand/category watchlist,
  push only for your matches.
- **V3:** scan-to-add capture, province filters, bilingual (EN/FR).
