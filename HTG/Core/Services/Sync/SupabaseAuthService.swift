import Foundation
import Supabase

/// Wraps Supabase Auth. Sign-in uses the native Sign in with Apple sheet;
/// the resulting identity token is exchanged for a Supabase session.
@MainActor
@Observable
final class SupabaseAuthService {
    private let client: SupabaseClient

    private(set) var currentUserID: UUID?

    var isSignedIn: Bool { currentUserID != nil }

    init(client: SupabaseClient) {
        self.client = client
    }

    /// Restores a persisted session on launch, if one exists.
    func restoreSession() async {
        currentUserID = try? await client.auth.session.user.id
    }

    func signInWithApple(idToken: String, nonce: String?) async throws {
        let session = try await client.auth.signInWithIdToken(
            credentials: OpenIDConnectCredentials(provider: .apple, idToken: idToken, nonce: nonce)
        )
        currentUserID = session.user.id
    }

    func signOut() async throws {
        try await client.auth.signOut()
        currentUserID = nil
    }
}
