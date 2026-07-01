import CryptoKit
import Foundation

struct SignUpRegistrationDraft {
    let email: String
    let passwordHash: String
}

enum SignUpValidationError: Error, Equatable {
    case invalidEmail
    case passwordTooShort
    case passwordMismatch

    var message: String {
        switch self {
        case .invalidEmail:
            return NSLocalizedString("Please enter a valid email", comment: "Sign up invalid email")
        case .passwordTooShort:
            return NSLocalizedString("Password must be at least 6 characters", comment: "Sign up password too short")
        case .passwordMismatch:
            return NSLocalizedString("Passwords do not match", comment: "Sign up password mismatch")
        }
    }
}

final class SignUpViewModel {
    let title = NSLocalizedString("Sign up", comment: "Sign up screen title")
    let emailPlaceholder = NSLocalizedString("Email", comment: "Email field placeholder")
    let passwordPlaceholder = NSLocalizedString("Password", comment: "Password field placeholder")
    let confirmPasswordPlaceholder = NSLocalizedString("Enter the password again", comment: "Confirm password placeholder")
    let signUpButtonTitle = NSLocalizedString("Sign up", comment: "Sign up button title")

    func makeRegistrationDraft(
        email: String?,
        password: String?,
        confirmPassword: String?
    ) -> Result<SignUpRegistrationDraft, SignUpValidationError> {
        let trimmedEmail = email?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let password = password ?? ""
        let confirmPassword = confirmPassword ?? ""

        guard Self.isValidEmail(trimmedEmail) else {
            return .failure(.invalidEmail)
        }

        guard password.count >= 6 else {
            return .failure(.passwordTooShort)
        }

        guard password == confirmPassword else {
            return .failure(.passwordMismatch)
        }

        return .success(SignUpRegistrationDraft(email: trimmedEmail, passwordHash: Self.hash(password)))
    }

    private static func isValidEmail(_ email: String) -> Bool {
        let pattern = #"^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}$"#
        return email.range(of: pattern, options: [.regularExpression, .caseInsensitive]) != nil
    }

    private static func hash(_ password: String) -> String {
        let digest = SHA256.hash(data: Data(password.utf8))
        return digest.map { String(format: "%02x", $0) }.joined()
    }
}
