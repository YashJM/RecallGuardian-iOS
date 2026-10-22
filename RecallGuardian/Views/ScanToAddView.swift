import SwiftUI

/// Scan a barcode → look it up → confirm the name → add to the watchlist.
struct ScanToAddView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(Watchlist.self) private var watchlist
    @State private var code: String?
    @State private var name = ""
    @State private var looking = false

    var body: some View {
        NavigationStack {
            Group {
                if let code {
                    confirm(code)
                } else if BarcodeScannerView.isSupported {
                    scanner
                } else {
                    unsupported
                }
            }
            .background(Theme.paper)
            .navigationTitle("Scan a product")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .tint(Theme.brand)
    }

    private var scanner: some View {
        ZStack(alignment: .bottom) {
            BarcodeScannerView { scanned in
                code = scanned
                looking = true
                Task {
                    let resolved = await ProductLookup.name(forBarcode: scanned)
                    name = resolved ?? ""
                    looking = false
                }
            }
            Text("Point at a product barcode")
                .font(.display(14, .semibold)).foregroundStyle(.white)
                .padding(.horizontal, 16).padding(.vertical, 10)
                .background(.black.opacity(0.55), in: Capsule())
                .padding(.bottom, 34)
        }
        .ignoresSafeArea(edges: .bottom)
    }

    private func confirm(_ code: String) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 6) {
                Text("SCANNED").font(.display(11, .semibold)).tracking(1).foregroundStyle(Theme.muted)
                Text(code).font(.system(size: 16, design: .monospaced)).foregroundStyle(Theme.ink)
            }

            if looking {
                HStack(spacing: 8) { ProgressView(); Text("Looking up…").foregroundStyle(Theme.muted) }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("PRODUCT OR BRAND TO WATCH")
                    .font(.display(11, .semibold)).tracking(1).foregroundStyle(Theme.muted)
                TextField("Product or brand name", text: $name)
                    .padding(12)
                    .background(Theme.surface, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous).stroke(Theme.line, lineWidth: 1))
                if !looking && name.isEmpty {
                    Text("We couldn't identify this barcode. Type the brand or product name to watch it.")
                        .font(.system(size: 12)).foregroundStyle(Theme.muted)
                }
            }

            Spacer()

            Button {
                watchlist.addBrand(name)
                dismiss()
            } label: {
                Text("Add to watchlist").font(.display(16, .semibold)).foregroundStyle(.white)
                    .frame(maxWidth: .infinity).padding(.vertical, 14)
                    .background(Theme.brand, in: RoundedRectangle(cornerRadius: 13, style: .continuous))
            }
            .disabled(name.trimmingCharacters(in: .whitespaces).count < 2)
            .opacity(name.trimmingCharacters(in: .whitespaces).count < 2 ? 0.5 : 1)

            Button("Scan again") { self.code = nil; name = "" }
                .font(.display(15, .semibold)).foregroundStyle(Theme.ink)
                .frame(maxWidth: .infinity)
        }
        .padding(20)
    }

    private var unsupported: some View {
        VStack(spacing: 14) {
            Image(systemName: "camera.metering.unknown")
                .font(.system(size: 42)).foregroundStyle(Theme.muted)
            Text("Scanning needs a camera").font(.display(18, .bold)).foregroundStyle(Theme.ink)
            Text("Barcode scanning works on your iPhone. On the simulator there's no camera — add brands by typing them on the Guardian screen.")
                .font(.system(size: 14)).foregroundStyle(Theme.muted)
                .multilineTextAlignment(.center)
        }
        .padding(32).frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
