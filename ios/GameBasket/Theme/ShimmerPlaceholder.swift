import SwiftUI

// A pulsing placeholder rectangle for content still loading. Used only
// where a bare spinner leaves an odd visual gap against the eventual
// content's real shape/size — GamesDiscoveryView's cover rows, where a
// lone ProgressView otherwise sits in a mostly-empty row. Most other
// loading states in the app are fine with a plain ProgressView plus a
// fade-in once content arrives; this isn't meant to replace those.
struct ShimmerPlaceholder: View {
    var cornerRadius: CGFloat = 10
    @State private var isPulsing = false

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(Color.gbSurface2)
            .opacity(isPulsing ? 0.4 : 0.8)
            .onAppear {
                withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) {
                    isPulsing = true
                }
            }
    }
}
