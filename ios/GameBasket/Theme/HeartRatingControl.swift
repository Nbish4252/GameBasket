import SwiftUI

// Tappable 5-heart rating input at half-heart precision, built from the
// same PixelHeart used everywhere ratings are displayed read-only — so
// the input looks identical to its own rendering elsewhere in the app.
// Each heart is split into two tap zones (left half = .5, right half =
// full); tapping the currently-set value again clears back to unrated,
// since this control has no other way to reach 0.
struct HeartRatingControl: View {
    @Binding var rating: Double
    var size: CGFloat = 30

    private let heartCount = 5
    private let spacing: CGFloat = 6

    // Only the tapped heart bounces (not the whole row) — a brief
    // overshoot-then-settle scale, matching the "single element reacts"
    // feel of iOS like/rating controls rather than animating all 5 at
    // once, which would read as noisier and less precise.
    @State private var bouncingIndex: Int?

    var body: some View {
        HStack(spacing: spacing) {
            ForEach(1...heartCount, id: \.self) { index in
                heart(for: index)
            }
        }
    }

    @ViewBuilder
    private func heart(for index: Int) -> some View {
        let fullValue = Double(index)
        let halfValue = fullValue - 0.5

        ZStack(alignment: .leading) {
            PixelHeart(filled: false)
            if rating >= fullValue {
                PixelHeart(filled: true)
            } else if rating >= halfValue {
                PixelHeart(filled: true)
                    .mask(alignment: .leading) {
                        Rectangle().frame(width: size / 2)
                    }
            }
        }
        .frame(width: size, height: size)
        .scaleEffect(bouncingIndex == index ? 1.18 : 1.0)
        .overlay {
            HStack(spacing: 0) {
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture { setRating(halfValue, at: index) }
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture { setRating(fullValue, at: index) }
            }
        }
    }

    private func setRating(_ value: Double, at index: Int) {
        withAnimation(.spring(response: 0.25, dampingFraction: 0.55)) {
            rating = rating == value ? 0 : value
        }
        bounce(index)
    }

    private func bounce(_ index: Int) {
        withAnimation(.spring(response: 0.18, dampingFraction: 0.4)) {
            bouncingIndex = index
        }
        Task {
            try? await Task.sleep(nanoseconds: 140_000_000)
            withAnimation(.spring(response: 0.25, dampingFraction: 0.6)) {
                if bouncingIndex == index {
                    bouncingIndex = nil
                }
            }
        }
    }
}
