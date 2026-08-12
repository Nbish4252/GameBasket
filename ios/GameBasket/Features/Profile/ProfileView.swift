import SwiftUI

struct ProfileView: View {
    let profile: Profile

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(profile.displayName ?? profile.username)
                .font(.title.bold())
            if let bio = profile.bio {
                Text(bio)
            }
        }
        .padding()
        // TODO: recent logs grid, follower/following counts, Steam
        // library linking entry point.
    }
}
