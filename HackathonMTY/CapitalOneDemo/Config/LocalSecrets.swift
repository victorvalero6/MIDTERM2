import Foundation

/// Local secrets configuration
/// In production, these should come from secure storage or build configuration
enum LocalSecrets {
    // Read from xcconfig via Info.plist, fallback to hardcoded
    static var nessieApiKey: String {
        if let key = Bundle.main.object(forInfoDictionaryKey: "API_KEY") as? String, !key.isEmpty {
            return key
        }
        return "65dfb406dc064d7c9e638642279e62ff"
    }
    
    // Customer ID from your actual API data
    static let nessieCustomerId = "68fd5ace9683f20dd51a497a"

    // Optional: Explicit checking account id for fetching purchases
    // If provided, we will fetch purchases for this account even if it's not returned in the accounts list
    static let nessieCheckingAccountId = "68fd5b5a9683f20dd51a497b"
}
