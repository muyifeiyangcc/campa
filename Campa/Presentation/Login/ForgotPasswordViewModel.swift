import CryptoKit
import Foundation

final class ForgotPasswordViewModel {
    let title = NSLocalizedString("Forgot password", comment: "Forgot password screen title")
    let emailPlaceholder = NSLocalizedString("Email", comment: "Email field placeholder")
    let passwordPlaceholder = NSLocalizedString("Password", comment: "Password field placeholder")
    let confirmPasswordPlaceholder = NSLocalizedString("Enter the password again", comment: "Confirm password placeholder")
    let submitButtonTitle = NSLocalizedString("Save", comment: "Forgot password submit button title")
    let emptyInputMessage = NSLocalizedString("Please complete all information", comment: "Forgot password required fields toast")
    let passwordTooShortMessage = NSLocalizedString("Password must be at least 6 characters", comment: "Forgot password password too short")
    let passwordMismatchMessage = NSLocalizedString("Passwords do not match", comment: "Forgot password mismatch toast")
    let saveSuccessMessage = NSLocalizedString("Password updated", comment: "Forgot password success toast")
    let saveFailedMessage = NSLocalizedString("Failed to update password", comment: "Forgot password failure toast")

    func hash(_ password: String) -> String {
        let digest = SHA256.hash(data: Data(password.utf8))
        return digest.map { String(format: "%02x", $0) }.joined()
    }
}
