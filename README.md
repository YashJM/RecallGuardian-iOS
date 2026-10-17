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
4. **App Transport Security** is fine: the feed is HTTPS. No extra entitlements
   for v1.
5. Build & run.

## Source layout

```
RecallGuardian/
├── RecallGuardianApp.swift   App entry + tab bar (Recalls · Guardian)
├── Models/
│   └── Recall.swift          Recall, RawRecall (feed decoding), Tier, Group
├── Services/
│   ├── RecallClassifier.swift  Grouping + severity + ranking  ← shared contract
│   └── RecallStore.swift       Fetch, decode, normalize, rank (@Observable)
├── Views/
│   ├── FeedView.swift          Ranked feed + category filter
│   ├── RecallRow.swift         The recall card (severity stripe)
│   └── RecallDetailView.swift  Full recall + official source link
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
