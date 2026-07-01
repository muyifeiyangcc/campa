import CryptoKit
import Foundation

final class LoginViewModel {
    let title = NSLocalizedString("Sign in", comment: "Login screen title")
    let emailPlaceholder = NSLocalizedString("Email", comment: "Email field placeholder")
    let passwordPlaceholder = NSLocalizedString("Password", comment: "Password field placeholder")
    let forgotPasswordTitle = NSLocalizedString("Forget ?", comment: "Forgot password action")
    let loginButtonTitle = NSLocalizedString("Login", comment: "Login button title")
    let emptyInputMessage = NSLocalizedString("    Email and password cannot be empty    ", comment: "Login empty input toast")
    let loginFailedMessage = NSLocalizedString("    Email or password is incorrect    ", comment: "Login failed toast")

    func hash(_ password: String) -> String {
        let digest = SHA256.hash(data: Data(password.utf8))
        return digest.map { String(format: "%02x", $0) }.joined()
    }
}
