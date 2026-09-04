import SwiftUI

// Honest placeholder, not a stub with fake data: Lists has no schema
// support yet (no `lists` table), so there's nothing real to show here.
// This tab exists to match the mockup's nav shape without pretending
// the feature is built.
struct ListsComingSoonView: View {
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "list.bullet.rectangle")
                .font(.system(size: 28))
                .foregroundStyle(Color.gbTextFaint)
            Text("Lists coming soon")
                .font(.balooSemiBold(15))
                .foregroundStyle(Color.gbText)
            Text("Curated game lists aren't built yet.")
                .font(.nunito(13))
                .foregroundStyle(Color.gbTextFaint)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.gbBackground)
    }
}
