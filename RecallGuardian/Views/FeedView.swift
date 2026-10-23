import SwiftUI

/// The ranked feed. Native search + ingredient suggestions, clean filter chips,
/// and scannable cards. Opens on Food.
struct FeedView: View {
    @Environment(RecallStore.self) private var store
    @Environment(AppRouter.self) private var router
    @State private var filter: RecallGroup? = .food
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
                    ProgressView().controlSize(.large)
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
        .searchable(text: $query, placement: .navigationBarDrawer(displayMode: .always),
                    prompt: "Product, brand or ingredient")
        .searchSuggestions {
            if !searching {
                ForEach(quick, id: \.self) { word in
                    Label(word, systemImage: "magnifyingglass").searchCompletion(word)
                }
            }
        }
        .task {
            await store.load()
            if Snapshot.openDetail, router.pendingNID == nil { router.pendingNID = store.feed.first?.nid }
            resolvePending()
        }
        .onChange(of: router.pendingNID) { _, _ in resolvePending() }
        .onChange(of: store.state) { _, _ in resolvePending() }
    }

    private var content: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                if searching {
                    HStack {
                        Text("\(shown.count) result\(shown.count == 1 ? "" : "s")")
                            .font(.subheadline.weight(.semibold)).foregroundStyle(Theme.muted)
                        Spacer()
                    }
                    .padding(.horizontal, 16).padding(.top, 6)
                } else {
                    filterBar
                }

                ForEach(shown) { recall in
                    NavigationLink(value: recall) { RecallRow(recall: recall) }
                        .buttonStyle(.plain)
                        .padding(.horizontal, 16)
                }

                if shown.isEmpty {
                    emptyState.padding(.horizontal, 24).padding(.top, 40)
                }
                Color.clear.frame(height: 8)
            }
            .padding(.top, 4)
        }
        .background(Theme.paper)
        .refreshable { await store.load(force: true) }
    }

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                chip(label: "All", group: nil, count: base.count)
                ForEach(RecallGroup.allCases) { g in
                    let c = count(g)
                    if c > 0 { chip(label: g.label, group: g, count: c) }
                }
            }
            .padding(.horizontal, 16).padding(.vertical, 10)
        }
        .background(Theme.paper)
    }

    private func chip(label: String, group: RecallGroup?, count: Int) -> some View {
        let on = filter == group
        return Button {
            withAnimation(.snappy(duration: 0.2)) { filter = group }
        } label: {
            HStack(spacing: 6) {
                if let group {
                    Image(systemName: Theme.symbol(group)).font(.system(size: 11, weight: .bold))
                }
                Text(label).font(.system(size: 14, weight: .semibold))
                Text("\(count)").font(.system(size: 13, weight: .medium)).opacity(0.55).monospacedDigit()
            }
            .foregroundStyle(on ? .white : Theme.ink)
            .padding(.horizontal, 13).padding(.vertical, 8)
            .background(on ? Theme.ink : Theme.surface, in: Capsule())
            .shadow(color: .black.opacity(on ? 0 : 0.04), radius: 4, y: 1)
        }
        .buttonStyle(.plain)
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: searching ? "checkmark.shield" : "tray")
                .font(.system(size: 34)).foregroundStyle(Theme.severity(.standard))
            Text(searching ? "No current recalls match “\(query.trimmingCharacters(in: .whitespaces))”"
                 : "Nothing in this category right now")
                .font(.system(size: 15, weight: .semibold)).foregroundStyle(Theme.ink)
                .multilineTextAlignment(.center)
            if searching {
                Text("That’s good news — check the official site for older recalls.")
                    .font(.system(size: 13)).foregroundStyle(Theme.muted)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func resolvePending() {
        guard let nid = router.pendingNID,
              let recall = store.recalls.first(where: { $0.nid == nid }) else { return }
        router.feedPath = [recall]
        router.pendingNID = nil
    }
}

struct ErrorView: View {
    let message: String
    let retry: () -> Void
    var body: some View {
        VStack(spacing: 14) {
            Text("Couldn't load recalls").font(.system(size: 18, weight: .bold)).foregroundStyle(Theme.ink)
            Text(message).font(.system(size: 14)).foregroundStyle(Theme.muted).multilineTextAlignment(.center)
            Button("Try again", action: retry).buttonStyle(.borderedProminent).tint(Theme.brand)
        }
        .padding(32).frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
