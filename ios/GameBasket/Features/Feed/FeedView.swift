import SwiftUI

enum FeedTopTab: String, CaseIterable {
    case games = "Games"
    case reviews = "Reviews"
    case lists = "Lists"
    case journal = "Journal"
}

struct FeedView: View {
    @State private var selectedTab: FeedTopTab = .games

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                topTabRow
                Divider().background(Color.gbLine)
                Group {
                    switch selectedTab {
                    case .games: GamesDiscoveryView()
                    case .reviews: ReviewsView()
                    case .lists: ListsComingSoonView()
                    case .journal: JournalView()
                    }
                }
            }
            .background(Color.gbBackground)
            .navigationTitle("Feed")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Feed")
                        .font(.balooBold(20))
                        .foregroundStyle(Color.gbText)
                }
            }
            .toolbarBackground(Color.gbBackground, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .preferredColorScheme(.dark)
    }

    // Mirrors the mockup's .tabs/.tab/.tab.active exactly: Nunito
    // ExtraBold 12.5px, text-faint when inactive, text color + a 3px
    // green underline bar when active.
    private var topTabRow: some View {
        HStack(spacing: 0) {
            ForEach(FeedTopTab.allCases, id: \.self) { tab in
                Button {
                    selectedTab = tab
                } label: {
                    VStack(spacing: 8) {
                        Text(tab.rawValue)
                            .font(.nunitoExtraBold(12.5))
                            .foregroundStyle(selectedTab == tab ? Color.gbText : Color.gbTextFaint)
                        Rectangle()
                            .fill(selectedTab == tab ? Color.gbGreen : Color.clear)
                            .frame(height: 3)
                            .clipShape(RoundedRectangle(cornerRadius: 3))
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, 14)
        .padding(.top, 4)
    }
}
