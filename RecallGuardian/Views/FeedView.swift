import SwiftUI

/// The ranked feed — the app's home. Opens on Food, searchable across
/// everything, with one-tap ingredient checks. Mirrors the web homepage.
struct FeedView: View {
    @Environment(RecallStore.self) private var store
    @Environment(AppRouter.self) private var router
    @State private var filter: RecallGroup? = .food   // nil == All
    @State private var query = ""

    private let limit = 200
    private let quick = ["Milk", "Eggs", "Cheese", "Peanut", "Wheat", "Beef", "Chicken", "Romaine"]

    private var base: [Recall] { Array(store.feed.prefix(limit)) }

    private var searching: Bool { !query.trimmingCharacters(in: .whitespaces).isEmpty }

    private var shown: [Recall] {
        let q = query.trimmingCharacters(in: .whitespaces).lowercased()
        if !q.isEmpty {
            return base.filter {
                "\($0.title) \($0.product) \($0.category) \($0.agency) \($0.issue)"
                    .lowercased().contains(q)
            }
        }
        guard let filter else { return base }
        return base.filter { $0.group == filter }
    }

    private func count(_ g: RecallGroup) -> Int { base.filter { $0.group == g }.count }

    var body: some View {
        @Bindable var router = router
        return NavigationStack(path: $router.feedPath) {
            Group {
                switch store.state {
                case .loading, .idle:
                    ProgressView("Loading recalls…")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                case .failed(let message):
                    ErrorView(message: message) { Task { await store.load(force: true) } }
                case .loaded:
                    content
                }
            }
            .background(Theme.paper)
            .navigationTitle("Recalls")
            .navigationDestination(for: Recall.self) { RecallDetailView(recall: $0) }
        }
        .tint(Theme.brand)
        .task {
            await store.load()
            // Simulate a notification deep-link through the real routing path.
            if Snapshot.openDetail, router.pendingNID == nil { router.pendingNID = store.feed.first?.nid }
            resolvePending()
        }
        .onChange(of: router.pendingNID) { _, _ in resolvePending() }
        .onChange(of: store.state) { _, _ in resolvePending() }
    }

    /// Push the recall a tapped notification asked for, once the feed has loaded.
    private func resolvePending() {
        guard let nid = router.pendingNID,
              let recall = store.recalls.first(where: { $0.nid == nid }) else { return }
        router.feedPath = [recall]
        router.pendingNID = nil
    }

    private var content: some View {
        ScrollView {
            VStack(spacing: 14) {
                searchBar
                quickChecks
                if !searching { filterChips }
                if searching {
                    HStack {
                        Text("\(shown.count) result\(shown.count == 1 ? "" : "s") for “\(query.trimmingCharacters(in: .whitespaces))”")
                            .font(.display(13, .semibold)).foregroundStyle(Theme.muted)
                        Spacer()
                    }
                }

                LazyVStack(spacing: 10) {
                    ForEach(shown) { recall in
                        NavigationLink(value: recall) { RecallRow(recall: recall) }
                            .buttonStyle(.plain)
                    }
                    if shown.isEmpty {
                        Text(searching
                             ? "No current recalls match “\(query.trimmingCharacters(in: .whitespaces))”. That's good news — check the official site for older recalls."
                             : "No recalls in this category right now.")
                            .font(.system(size: 14)).foregroundStyle(Theme.muted)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity).padding(.top, 40)
                    }
                }
            }
            .padding(16)
        }
        .background(Theme.paper)
        .refreshable { await store.load(force: true) }
    }

    private var searchBar: some View {
        HStack(spacing: 9) {
            Image(systemName: "magnifyingglass").foregroundStyle(Theme.muted)
            TextField("Check a product, brand or ingredient", text: $query)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
            if searching {
                Button { query = "" } label: {
                    Image(systemName: "xmark.circle.fill").foregroundStyle(Theme.muted)
                }
            }
        }
        .padding(12)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: 11, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 11, style: .continuous).stroke(Theme.line, lineWidth: 1.5))
    }

    private var quickChecks: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                Text("Quick check").font(.display(12, .semibold)).foregroundStyle(Theme.muted)
                ForEach(quick, id: \.self) { word in
                    Button { query = word } label: {
                        Text(word).font(.display(13, .semibold)).foregroundStyle(Theme.ink)
                            .padding(.horizontal, 12).padding(.vertical, 6)
                            .background(Theme.surface, in: Capsule())
                            .overlay(Capsule().stroke(Theme.line, lineWidth: 1))
                    }
                }
            }
            .padding(.vertical, 1)
        }
    }

    private var filterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                chip(label: "All", group: nil, count: base.count)
                ForEach(RecallGroup.allCases) { g in
                    let c = count(g)
                    if c > 0 { chip(label: g.label, group: g, count: c) }
                }
            }
            .padding(.vertical, 1)
        }
    }

    private func chip(label: String, group: RecallGroup?, count: Int) -> some View {
        let on = filter == group
        return Button { filter = group } label: {
            HStack(spacing: 6) {
                if let group {
                    Image(systemName: Theme.symbol(group))
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(on ? Theme.paper : Theme.category(group))
                }
                Text(label).font(.display(14, .semibold))
                Text("\(count)").font(.display(13, .medium)).opacity(0.6).monospacedDigit()
            }
            .foregroundStyle(on ? Theme.paper : Theme.muted)
            .padding(.horizontal, 13).padding(.vertical, 8)
            .background(on ? Theme.navy : Theme.surface, in: Capsule())
            .overlay(Capsule().stroke(Theme.line, lineWidth: on ? 0 : 1))
        }
        .buttonStyle(.plain)
    }
}

struct ErrorView: View {
    let message: String
    let retry: () -> Void
    var body: some View {
        VStack(spacing: 14) {
            Text("Couldn't load recalls").font(.display(18, .bold)).foregroundStyle(Theme.ink)
            Text(message).font(.system(size: 14)).foregroundStyle(Theme.muted)
                .multilineTextAlignment(.center)
            Button("Try again", action: retry)
                .buttonStyle(.borderedProminent).tint(Theme.brand)
        }
        .padding(32).frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
