import SwiftUI
import UserNotifications

/// The Guardian: a private, on-device watchlist. Add the brands you own and the
/// categories you care about; the app checks new recalls against them in the
/// background and notifies you only on a match. Nothing leaves the device.
struct GuardianView: View {
    @Environment(Watchlist.self) private var watchlist
    @Environment(RecallStore.self) private var store
    @Environment(AlertPreferences.self) private var prefs
    @Environment(UpdateChecker.self) private var updates
    @State private var brandText = ""
    @State private var notifStatus: UNAuthorizationStatus = .notDetermined

    private var matches: [(recall: Recall, item: WatchItem)] {
        WatchMatcher.matches(in: store.feed, items: watchlist.items)
            .map { (recall: $0.0, item: $0.1) }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    if let update = updates.available, !updates.isPresenting {
                        UpdateAvailableRow(update: update)
                    }
                    intro
                    alertsCard
                    brandsSection
                    categoriesSection
                    matchesSection
                }
                .padding(16)
            }
            .background(Theme.paper)
            .navigationTitle("Guardian")
            .navigationDestination(for: Recall.self) { RecallDetailView(recall: $0) }
        }
        .tint(Theme.brand)
        .task {
            await store.load()
            notifStatus = await NotificationManager.authorizationStatus()
        }
    }

    // MARK: Sections

    private var intro: some View {
        Text("Tell RecallGuardian what your household owns. It checks new recalls against your list in the background and alerts you only on a match. Your list stays on this device.")
            .font(.system(size: 14))
            .foregroundStyle(Theme.muted)
    }

    @ViewBuilder
    private var alertsCard: some View {
        @Bindable var prefs = prefs
        VStack(alignment: .leading, spacing: 0) {
            Toggle(isOn: Binding(
                get: { prefs.enabled },
                set: { setAlerts(on: $0) }
            )) {
                HStack(spacing: 11) {
                    Image(systemName: prefs.enabled ? "bell.badge.fill" : "bell.slash")
                        .font(.system(size: 19))
                        .foregroundStyle(prefs.enabled ? Theme.severity(.standard) : Theme.muted)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Recall alerts").font(.display(15, .bold)).foregroundStyle(Theme.ink)
                        Text(prefs.enabled ? "You'll be notified when a match appears." : "Get notified when something you watch is recalled.")
                            .font(.system(size: 12)).foregroundStyle(Theme.muted)
                    }
                }
            }
            .tint(Theme.brand)

            if prefs.enabled {
                Divider().padding(.vertical, 12)
                Text("ALERT ME ABOUT")
                    .font(.display(11, .semibold)).tracking(1.1).foregroundStyle(Theme.muted)
                    .padding(.bottom, 8)
                Picker("Severity", selection: $prefs.threshold) {
                    ForEach(SeverityThreshold.allCases) { Text($0.label).tag($0) }
                }
                .pickerStyle(.segmented)

                if notifStatus == .denied {
                    Text("Notifications are turned off for RecallGuardian in Settings. Matches will still appear here.")
                        .font(.system(size: 12)).foregroundStyle(Theme.severity(.high))
                        .padding(.top, 10)
                }
            }
        }
        .padding(14)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.line, lineWidth: 1))
    }

    private var brandsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel("Brands & products you own")
            HStack(spacing: 8) {
                TextField("Add a brand or product…", text: $brandText)
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled()
                    .padding(10)
                    .background(Theme.surface, in: RoundedRectangle(cornerRadius: 9))
                    .overlay(RoundedRectangle(cornerRadius: 9).stroke(Theme.line, lineWidth: 1))
                    .onSubmit(addBrand)
                Button(action: addBrand) {
                    Image(systemName: "plus").font(.system(size: 15, weight: .bold))
                        .frame(width: 42, height: 42)
                        .background(Theme.ink, in: RoundedRectangle(cornerRadius: 9))
                        .foregroundStyle(Theme.paper)
                }
                .disabled(brandText.trimmingCharacters(in: .whitespaces).count < 2)
            }
            if watchlist.brands.isEmpty {
                Text("e.g. your car make, a stroller brand, the meds in your cabinet.")
                    .font(.system(size: 12)).foregroundStyle(Theme.muted)
            } else {
                ForEach(watchlist.brands) { item in
                    HStack {
                        Image(systemName: "tag.fill").font(.system(size: 12)).foregroundStyle(Theme.muted)
                        Text(item.label).font(.display(14, .medium)).foregroundStyle(Theme.ink)
                        Spacer()
                        Button { watchlist.remove(item) } label: {
                            Image(systemName: "xmark.circle.fill").foregroundStyle(Theme.muted)
                        }
                    }
                    .padding(.horizontal, 12).padding(.vertical, 9)
                    .background(Theme.surface, in: RoundedRectangle(cornerRadius: 9))
                    .overlay(RoundedRectangle(cornerRadius: 9).stroke(Theme.line, lineWidth: 1))
                }
            }
        }
    }

    private var categoriesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel("Categories to watch")
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                ForEach(RecallGroup.allCases) { group in
                    let on = watchlist.isWatching(group)
                    Button { watchlist.toggleCategory(group) } label: {
                        HStack {
                            Image(systemName: on ? "checkmark.circle.fill" : "circle")
                            Text(group.label)
                            Spacer()
                        }
                        .font(.display(14, .semibold))
                        .foregroundStyle(on ? Theme.paper : Theme.ink)
                        .padding(.horizontal, 12).padding(.vertical, 10)
                        .background(on ? Theme.ink : Theme.surface, in: RoundedRectangle(cornerRadius: 9))
                        .overlay(RoundedRectangle(cornerRadius: 9).stroke(Theme.line, lineWidth: on ? 0 : 1))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    @ViewBuilder
    private var matchesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel("Matches in current recalls")
            if watchlist.items.isEmpty {
                emptyHint("Add a brand or category above to start watching.")
            } else if matches.isEmpty {
                emptyHint("Good news — nothing you're watching has an active recall.")
            } else {
                ForEach(matches, id: \.recall.nid) { pair in
                    NavigationLink(value: pair.recall) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Matches \(pair.item.label)")
                                .font(.display(11, .bold)).textCase(.uppercase)
                                .foregroundStyle(Theme.brand)
                            RecallRow(recall: pair.recall)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: Helpers

    private func sectionLabel(_ t: String) -> some View {
        Text(t.uppercased())
            .font(.display(12, .semibold)).tracking(1.2)
            .foregroundStyle(Theme.muted)
    }

    private func emptyHint(_ t: String) -> some View {
        Text(t).font(.system(size: 14)).foregroundStyle(Theme.muted)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
            .background(Theme.surface, in: RoundedRectangle(cornerRadius: 11))
            .overlay(RoundedRectangle(cornerRadius: 11).stroke(Theme.line, lineWidth: 1))
    }

    private func addBrand() {
        watchlist.addBrand(brandText)
        brandText = ""
    }

    private func setAlerts(on: Bool) {
        prefs.enabled = on
        guard on else { return }
        Task {
            _ = await NotificationManager.requestAuthorization()
            notifStatus = await NotificationManager.authorizationStatus()
            // Don't blast the existing backlog — treat everything that already
            // matches as seen, so only genuinely new recalls notify.
            BackgroundRefresh.primeSeen(with: store.recalls, items: watchlist.items)
            BackgroundRefresh.schedule()
        }
    }
}
