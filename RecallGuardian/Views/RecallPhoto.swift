import SwiftUI

/// The product photo for a recall — fetched lazily from the official notice and
/// cached. Falls back to a clean category tile when there's no image.
struct RecallPhoto: View {
    let recall: Recall
    var corner: CGFloat = 12
    @State private var url: URL?
    @State private var tried = false

    var body: some View {
        ZStack {
            Theme.category(recall.group).opacity(0.12)
            if let url {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image): image.resizable().scaledToFill()
                    default: placeholder
                    }
                }
            } else {
                placeholder
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: corner, style: .continuous))
        .task(id: recall.nid) { await resolve() }
    }

    private var placeholder: some View {
        GeometryReader { geo in
            Image(systemName: Theme.symbol(recall.group))
                .font(.system(size: min(geo.size.width, geo.size.height) * 0.36, weight: .medium))
                .foregroundStyle(Theme.category(recall.group).opacity(0.9))
                .frame(width: geo.size.width, height: geo.size.height)
        }
    }

    private func resolve() async {
        guard !tried else { return }
        tried = true
        url = await RecallExtrasService.shared.extras(for: recall).imageURL
    }
}
