import UIKit

final class ForgotPasswordViewController: BaseViewController {
    private enum Constants {
        static let horizontalInset: CGFloat = 30
        static let fieldHeight: CGFloat = 64
        static let buttonHeight: CGFloat = 62
    }

    private let viewModel: ForgotPasswordViewModel
    private let userRepository: UserRepository
    private let titleLabel = UILabel()
    private let emailField = IconTextField(iconName: "email")
    private let passwordField = IconTextField(iconName: "password")
    private let confirmPasswordField = IconTextField(iconName: "password")
    private let submitButton = UIButton(type: .custom)

    init(viewModel: ForgotPasswordViewModel = ForgotPasswordViewModel(), userRepository: UserRepository = UserRepository()) {
        self.viewModel = viewModel
        self.userRepository = userRepository
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.navType = .back
        configureTitleLabel()
        configureFields()
        configureSubmitButton()
        configureLayout()
    }

    private func configureTitleLabel() {
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = viewModel.title
        titleLabel.font = AppFont.semibold(size: 21)
        titleLabel.textColor = UIColor(red: 0.28, green: 0.20, blue: 0.16, alpha: 1.0)
        titleLabel.textAlignment = .center
    }

    private func configureFields() {
        emailField.translatesAutoresizingMaskIntoConstraints = false
        emailField.placeholder = viewModel.emailPlaceholder
        emailField.keyboardType = .emailAddress
        emailField.textContentType = .emailAddress
        emailField.autocapitalizationType = .none
        emailField.accessibilityIdentifier = "forgotPasswordEmailField"

        passwordField.translatesAutoresizingMaskIntoConstraints = false
        passwordField.placeholder = viewModel.passwordPlaceholder
        passwordField.textContentType = .newPassword
        passwordField.isSecureTextEntry = true
        passwordField.accessibilityIdentifier = "forgotPasswordPasswordField"

        confirmPasswordField.translatesAutoresizingMaskIntoConstraints = false
        confirmPasswordField.placeholder = viewModel.confirmPasswordPlaceholder
        confirmPasswordField.textContentType = .newPassword
        confirmPasswordField.isSecureTextEntry = true
        confirmPasswordField.accessibilityIdentifier = "forgotPasswordConfirmPasswordField"
    }

    private func configureSubmitButton() {
        submitButton.translatesAutoresizingMaskIntoConstraints = false
        submitButton.setTitle(viewModel.submitButtonTitle, for: .normal)
        submitButton.setTitleColor(.white, for: .normal)
        submitButton.titleLabel?.font = AppFont.semibold(size: 18)
        submitButton.backgroundColor = UIColor(red: 0.28, green: 0.02, blue: 0.01, alpha: 1.0)
        submitButton.layer.cornerRadius = Constants.buttonHeight / 2
        submitButton.accessibilityIdentifier = "forgotPasswordSubmitButton"
        submitButton.addTarget(self, action: #selector(clickSaveAction), for: .touchUpInside)
    }

    private func configureLayout() {
        view.addSubview(titleLabel)
        view.addSubview(emailField)
        view.addSubview(passwordField)
        view.addSubview(confirmPasswordField)
        view.addSubview(submitButton)

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 74),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            emailField.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 74),
            emailField.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: Constants.horizontalInset),
            emailField.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -Constants.horizontalInset),
            emailField.heightAnchor.constraint(equalToConstant: Constants.fieldHeight),

            passwordField.topAnchor.constraint(equalTo: emailField.bottomAnchor, constant: 22),
            passwordField.leadingAnchor.constraint(equalTo: emailField.leadingAnchor),
            passwordField.trailingAnchor.constraint(equalTo: emailField.trailingAnchor),
            passwordField.heightAnchor.constraint(equalToConstant: Constants.fieldHeight),

            confirmPasswordField.topAnchor.constraint(equalTo: passwordField.bottomAnchor, constant: 22),
            confirmPasswordField.leadingAnchor.constraint(equalTo: emailField.leadingAnchor),
            confirmPasswordField.trailingAnchor.constraint(equalTo: emailField.trailingAnchor),
            confirmPasswordField.heightAnchor.constraint(equalToConstant: Constants.fieldHeight),

            submitButton.topAnchor.constraint(equalTo: confirmPasswordField.bottomAnchor, constant: 88),
            submitButton.leadingAnchor.constraint(equalTo: emailField.leadingAnchor, constant: 25),
            submitButton.trailingAnchor.constraint(equalTo: emailField.trailingAnchor, constant: -25),
            submitButton.heightAnchor.constraint(equalToConstant: Constants.buttonHeight)
        ])
    }

    @objc private func clickSaveAction() {
        let email = emailField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let password = passwordField.text ?? ""
        let confirmPassword = confirmPasswordField.text ?? ""

        guard !email.isEmpty, !password.isEmpty, !confirmPassword.isEmpty else {
            showToast(message: viewModel.emptyInputMessage)
            return
        }

        guard password.count >= 6 else {
            showToast(message: viewModel.passwordTooShortMessage)
            return
        }

        guard password == confirmPassword else {
            showToast(message: viewModel.passwordMismatchMessage)
            return
        }

        switch userRepository.updatePassword(email: email, passwordHash: viewModel.hash(password)) {
        case .success:
            showToast(message: viewModel.saveSuccessMessage)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { [weak self] in
                self?.navigationController?.popViewController(animated: true)
            }
        case .failure:
            showToast(message: viewModel.saveFailedMessage)
        }
    }

    private func showToast(message: String) {
        AppToast.show(
            message: message,
            in: view,
            relation: .above(submitButton.topAnchor, spacing: 18),
            accessibilityIdentifier: "forgotPasswordToastLabel"
        )
    }
}
