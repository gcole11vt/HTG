import Foundation
import SwiftData
import AuthenticationServices

/// UI state for the Profile page's Account & Sync card: Sign in with Apple,
/// manual sync, and sign-out. All heavy lifting lives in the sync services.
@MainActor
@Observable
final class AccountSyncManager {
    enum SyncState: Equatable {
        case idle
        case syncing
        case success(Date)
        case failure(String)
    }

    private let modelContext: ModelContext
    private let authService: SupabaseAuthService?

    private(set) var syncState: SyncState = .idle

    var isConfigured: Bool { authService != nil }
    var isSignedIn: Bool { authService?.isSignedIn ?? false }

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        if let client = SupabaseClientProvider.shared {
            authService = SupabaseAuthService(client: client)
        } else {
            authService = nil
        }
    }

    /// Restores a persisted session on appear and syncs if signed in.
    func restoreSession() async {
        await authService?.restoreSession()
        if isSignedIn {
            await sync()
        }
    }

    func handleSignInWithApple(_ result: Result<ASAuthorization, Error>) async {
        guard let authService else { return }

        switch result {
        case .success(let authorization):
            guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
                  let tokenData = credential.identityToken,
                  let idToken = String(data: tokenData, encoding: .utf8) else {
                syncState = .failure("Could not read the Apple identity token.")
                return
            }
            do {
                try await authService.signInWithApple(idToken: idToken, nonce: nil)
                await sync()
            } catch {
                syncState = .failure(error.localizedDescription)
            }
        case .failure(let error):
            guard (error as? ASAuthorizationError)?.code != .canceled else { return }
            syncState = .failure(error.localizedDescription)
        }
    }

    func sync() async {
        guard let client = SupabaseClientProvider.shared,
              let userID = authService?.currentUserID else { return }

        syncState = .syncing
        do {
            let service = SyncService(
                modelContext: modelContext,
                remoteStore: SupabaseRemoteStore(client: client),
                userID: userID
            )
            try await service.syncAll()
            syncState = .success(Date())
        } catch {
            syncState = .failure(error.localizedDescription)
        }
    }

    func signOut() async {
        try? await authService?.signOut()
        syncState = .idle
    }
}
