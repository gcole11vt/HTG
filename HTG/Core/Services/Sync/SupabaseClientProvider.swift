import Foundation
import Supabase

/// Fill these in from your Supabase project (Dashboard → Settings → API).
/// See `docs/supabase/setup.md`. The anon key is safe to ship in the app;
/// row-level security scopes all data access to the signed-in user.
enum SupabaseConfig {
    static let projectURL = "https://patarifvkyxlaxqjzmww.supabase.co"
    static let anonKey = "sb_publishable_qzndMy6YM3FPyDAwNUjMJg_G3D4ElAk"

    static var isConfigured: Bool {
        !projectURL.contains("YOUR-") && !anonKey.contains("YOUR-")
    }
}

enum SupabaseClientProvider {
    /// `nil` until `SupabaseConfig` is filled in, so the app runs fully
    /// offline-only without a Supabase project.
    static let shared: SupabaseClient? = {
        guard SupabaseConfig.isConfigured, let url = URL(string: SupabaseConfig.projectURL) else {
            return nil
        }
        return SupabaseClient(supabaseURL: url, supabaseKey: SupabaseConfig.anonKey)
    }()
}
