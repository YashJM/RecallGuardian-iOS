import SwiftUI

/// The ranked feed — the app's home. Fully usable with no account or setup.
struct FeedView: View {
    @Environment(RecallStore.self) private var store
    @State private var filter: Group? = nil   // nil == All

    private let homeLimit = 150

    private var feed: [Recall] {
        Array(store.feed.prefix(homeLimit))
    }
    private var shown: [Recall] {
        guard let filter else { return feed }
        return feed.filter { $0.group == filter }
    }

    var body: some View {
        NavigationStack {
            Group {
                switch store.state {
                case .loading, .idle:
                    ProgressView("Loading recalls…")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                case .failed(let message):
                    ErrorView(message: message) { Task { await store.load(force: true) } }
                case .loaded:
                    feedList
                }
            }
            .background(Theme.paper)
            .navigationTitle("Recalls")
            .navigationBarTitleDisplayMode(.large)
        }
        .tint(Theme.brand)
        .task { await store.load() }
    }

    private var feedList: some View {
        let counts = store.counts(in: feed)
        return ScrollView {
            FilterBar(filter: $filter, counts: counts, total: feed.count)
                .padding(.horizontal, 16)
                .padding(.bottom, 4)

            LazyVStack(spacing: 12) {
                ForEach(shown) { recall in
                    NavigationLink(value: recall) {
                        RecallRow(recall: recall)
                    }
                    .buttonStyle(.plain)
                }
                if shown.isEmpty {
                    Text("No recalls in this category right now.")
                        .font(.system(size: 15))
                        .foregroundStyle(Theme.muted)
                        .padding(.top, 40)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
        }
        .background(Theme.paper)
        .navigationDestination(for: Recall.self) { RecallDetailView(recall: $0) }
        .refreshable { await store.load(force: true) }
    }
}

private struct FilterBar: View {
    @Binding var filter: Group?
    let counts: [Group: Int]
    let total: Int

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                Chip(title: "All", count: total, selected: filter == nil) { filter = nil }
                ForEach(Group.allCases) { group in
                    let n = counts[group] ?? 0
                    if n > 0 {
                        Chip(title: group.label, count: n, selected: filter == group) {
                            filter = filter == group ? nil : group
                        }
                    }
                }
            }
            .padding(.vertical, 8)
        }
    }

    private struct Chip: View {
        let title: String
        let count: Int
        let selected: Bool
        let action: () -> Void

        var body: some View {
            Button(action: action) {
                HStack(spacing: 5) {
                    Text(title).font(.display(14, .semibold))
                    Text("\(count)")
                        .font(.display(13, .medium))
                        .opacity(0.6)
                        .monospacedDigit()
                }
                .foregroundStyle(selected ? Theme.paper : Theme.muted)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(selected ? Theme.ink : Theme.surface, in: Capsule())
                .overlay(Capsule().stroke(Theme.line, lineWidth: selected ? 0 : 1))
            }
            .buttonStyle(.plain)
        }
    }
}

private struct ErrorView: View {
    let message: String
    let retry: () -> Void
    var body: some View {
        VStack(spacing: 14) {
            Text("Couldn’t load recalls")
                .font(.display(18, .bold))
                .foregroundStyle(Theme.ink)
            Text(message)
                .font(.system(size: 14))
                .foregroundStyle(Theme.muted)
                .multilineTextAlignment(.center)
            Button("Try again", action: retry)
                .buttonStyle(.borderedProminent)
                .tint(Theme.brand)
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
