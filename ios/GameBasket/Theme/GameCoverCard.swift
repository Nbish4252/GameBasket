import SwiftUI

// Cover art + gradient + title, used in GamesDiscoveryView's horizontal
// discovery rows and Search's trending grid — extracted here once it
// was needed in both places, so the two don't duplicate the same
// gradient/clip/frame logic.
struct GameCoverCard: View {
    let url: String?
    let title: String
    var size: CGSize = CGSize(width: 88, height: 118)

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            AsyncImage(url: url.flatMap(URL.init)) { image in
                image.resizable().aspectRatio(contentMode: .fill)
            } placeholder: {
                Color.gbSurface2
            }
            .frame(width: size.width, height: size.height)
            .clipped()

            LinearGradient(
                colors: [.clear, .black.opacity(0.75)],
                startPoint: .center,
                endPoint: .bottom
            )
            .frame(width: size.width, height: size.height)

            Text(title)
                .font(.balooSemiBold(11))
                .foregroundStyle(.white)
                .lineLimit(2)
                .padding(8)
        }
        .frame(width: size.width, height: size.height)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}
