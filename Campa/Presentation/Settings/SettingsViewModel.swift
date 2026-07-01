import Foundation

final class SettingsViewModel {
    let rows: [SettingsRow] = [
        SettingsRow(title: NSLocalizedString("Edit Profile", comment: "Settings item")),
        SettingsRow(title: NSLocalizedString("Blacklist", comment: "Settings item")),
        SettingsRow(title: NSLocalizedString("Wallet", comment: "Settings item")),
        SettingsRow(title: NSLocalizedString("User Agreement", comment: "Settings item")),
        SettingsRow(title: NSLocalizedString("Privacy Policy", comment: "Settings item"))
    ]

    let deleteAccountTitle = NSLocalizedString("Delete Account", comment: "Delete account button title")
    let logOutTitle = NSLocalizedString("Log Out", comment: "Log out button title")
}

struct SettingsRow {
    let title: String
}
