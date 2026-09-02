import SwiftUI

// Hand-ported from the mockup's 7x7 pixel-grid heart (design/gamebasket_ui.html
// .heart-icon — 33 individual <rect> cells with shape-rendering:crispEdges).
// Reproduced natively instead of importing an asset: no SVG rasterizer was
// available to convert it, and a plain Canvas grid is pixel-exact anyway.
struct PixelHeart: View {
    var filled: Bool = true
    var color: Color = .gbHeart

    private static let cells: [(Int, Int)] = [
        (1, 0), (2, 0), (4, 0), (5, 0),
        (0, 1), (1, 1), (2, 1), (3, 1), (4, 1), (5, 1), (6, 1),
        (0, 2), (1, 2), (2, 2), (3, 2), (4, 2), (5, 2), (6, 2),
        (0, 3), (1, 3), (2, 3), (3, 3), (4, 3), (5, 3), (6, 3),
        (1, 4), (2, 4), (3, 4), (4, 4), (5, 4),
        (2, 5), (3, 5), (4, 5),
        (3, 6),
    ]

    var body: some View {
        Canvas { context, size in
            let cellSize = size.width / 7
            for (x, y) in Self.cells {
                let rect = CGRect(
                    x: CGFloat(x) * cellSize,
                    y: CGFloat(y) * cellSize,
                    width: cellSize,
                    height: cellSize
                )
                context.fill(Path(rect), with: .color(color))
            }
        }
        .opacity(filled ? 1 : 0.25)
        .aspectRatio(1, contentMode: .fit)
    }
}
