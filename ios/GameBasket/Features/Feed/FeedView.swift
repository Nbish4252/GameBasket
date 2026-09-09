import SwiftUI

enum FeedTopTab: String, CaseIterable {
    case games = "Games"
    case reviews = "Reviews"
    case lists = "Lists"
    case journal = "Journal"

    fileprivate var index: Int { Self.allCases.firstIndex(of: self) ?? 0 }
}

struct FeedView: View {
    @State private var selectedTab: FeedTopTab = .games
    // Which way the content should slide — set right before the
    // withAnimation that changes selectedTab, based on whether the
    // newly tapped tab sits left or right of the current one, so
    // switching to a later tab slides content in from the trailing
    // edge and switching to an earlier one slides in from leading —
    // matching how the underline bar moves.
    @State private var slideEdge: Edge = .trailing
    @Namespace private var underlineNamespace

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                topTabRow
                Divider().background(Color.gbLine)
                ZStack {
                    switch selectedTab {
                    case .games: GamesDiscoveryView()
                    case .reviews: ReviewsView()
                    case .lists: ListsComingSoonView()
                    case .journal: JournalView()
                    }
                }
                .transition(.asymmetric(
                    insertion: .move(edge: slideEdge).combined(with: .opacity),
                    removal: .move(edge: slideEdge == .trailing ? .leading : .trailing).combined(with: .opacity)
                ))
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
    // green underline bar when active — now sliding between tabs via
    // matchedGeometryEffect instead of just appearing/disappearing.
    private var topTabRow: some View {
        HStack(spacing: 0) {
            ForEach(FeedTopTab.allCases, id: \.self) { tab in
                Button {
                    select(tab)
                } label: {
                    VStack(spacing: 8) {
                        Text(tab.rawValue)
                            .font(.nunitoExtraBold(12.5))
                            .foregroundStyle(selectedTab == tab ? Color.gbText : Color.gbTextFaint)
                        ZStack {
                            if selectedTab == tab {
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(Color.gbGreen)
                                    .matchedGeometryEffect(id: "underline", in: underlineNamespace)
                            }
                        }
                        .frame(height: 3)
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, 14)
        .padding(.top, 4)
    }

    private func select(_ tab: FeedTopTab) {
        guard tab != selectedTab else { return }
        slideEdge = tab.index > selectedTab.index ? .trailing : .leading
        withAnimation(.easeInOut(duration: 0.22)) {
            selectedTab = tab
        }
    }
}
