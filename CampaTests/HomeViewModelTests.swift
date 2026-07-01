import XCTest
@testable import Campa

final class HomeViewModelTests: XCTestCase {
    func testTitleReturnsAppName() {
        let viewModel = HomeViewModel()

        XCTAssertEqual(viewModel.title, "Campa")
    }
}

final class SplashViewModelTests: XCTestCase {
    func testSplashContentMatchesFirstDesignPage() {
        let viewModel = SplashViewModel()

        XCTAssertEqual(viewModel.title, "Campa")
        XCTAssertEqual(viewModel.logoText, "C")
    }
}

final class LoginViewModelTests: XCTestCase {
    func testLoginContentMatchesDesign() {
        let viewModel = LoginViewModel()

        XCTAssertEqual(viewModel.title, "Sign in")
        XCTAssertEqual(viewModel.emailPlaceholder, "Email")
        XCTAssertEqual(viewModel.passwordPlaceholder, "Password")
        XCTAssertEqual(viewModel.forgotPasswordTitle, "Forget ?")
        XCTAssertEqual(viewModel.loginButtonTitle, "Login")
    }
}

final class SignUpViewModelTests: XCTestCase {
    func testRegistrationRequiresPasswordAtLeastSixCharacters() {
        let viewModel = SignUpViewModel()

        let result = viewModel.makeRegistrationDraft(
            email: "ari@example.com",
            password: "12345",
            confirmPassword: "12345"
        )

        if case .failure(.passwordTooShort) = result {
            return
        }

        XCTFail("Expected passwordTooShort validation failure")
    }

    func testRegistrationRequiresMatchingPasswords() {
        let viewModel = SignUpViewModel()

        let result = viewModel.makeRegistrationDraft(
            email: "ari@example.com",
            password: "123456",
            confirmPassword: "654321"
        )

        if case .failure(.passwordMismatch) = result {
            return
        }

        XCTFail("Expected passwordMismatch validation failure")
    }

    func testRegistrationDraftStoresPasswordHash() throws {
        let viewModel = SignUpViewModel()

        let draft = try viewModel.makeRegistrationDraft(
            email: "ari@example.com",
            password: "123456",
            confirmPassword: "123456"
        ).get()

        XCTAssertEqual(draft.email, "ari@example.com")
        XCTAssertNotEqual(draft.passwordHash, "123456")
        XCTAssertFalse(draft.passwordHash.isEmpty)
    }
}

final class PersonalInfoViewModelTests: XCTestCase {
    func testDefaultGenderIsMale() {
        let viewModel = PersonalInfoViewModel()

        XCTAssertEqual(viewModel.defaultGender, .male)
    }
}

final class AuthEntryViewModelTests: XCTestCase {
    func testAuthEntryContentMatchesDesign() {
        let viewModel = AuthEntryViewModel()

        XCTAssertEqual(viewModel.appName, "Campa")
        XCTAssertEqual(viewModel.loginByEmailTitle, "Login by email")
        XCTAssertEqual(viewModel.newUserTitle, "I'm new")
        XCTAssertEqual(viewModel.signUpPrompt, "Don't have an account? Sign up")
        XCTAssertEqual(viewModel.otherLoginMethodsTitle, "Other login methods")
        XCTAssertEqual(viewModel.agreementTitle, "Agree with User Agreement and Privacy Policy")
    }
}
