import UIKit

final class SignUpViewController: BaseViewController {
    private enum Constants {
        static let horizontalInset: CGFloat = 30
        static let fieldHeight: CGFloat = 64
        static let buttonHeight: CGFloat = 62
    }

    private let viewModel: SignUpViewModel
    private let titleLabel = UILabel()
    private let emailField = IconTextField(iconName: "email")
    private let passwordField = IconTextField(iconName: "password")
    private let confirmPasswordField = IconTextField(iconName: "password")
    private let signUpButton = UIButton(type: .system)

    init(viewModel: SignUpViewModel = SignUpViewModel()) {
        self.viewModel = viewModel
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
        configureSignUpButton()
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
        emailField.accessibilityIdentifier = "signUpEmailField"

        passwordField.translatesAutoresizingMaskIntoConstraints = false
        passwordField.placeholder = viewModel.passwordPlaceholder
        passwordField.textContentType = .newPassword
        passwordField.isSecureTextEntry = true
        passwordField.accessibilityIdentifier = "signUpPasswordField"

        confirmPasswordField.translatesAutoresizingMaskIntoConstraints = false
        confirmPasswordField.placeholder = viewModel.confirmPasswordPlaceholder
        confirmPasswordField.textContentType = .newPassword
        confirmPasswordField.isSecureTextEntry = true
        confirmPasswordField.accessibilityIdentifier = "signUpConfirmPasswordField"
    }

    private func configureSignUpButton() {
        signUpButton.translatesAutoresizingMaskIntoConstraints = false
        signUpButton.setTitle(viewModel.signUpButtonTitle, for: .normal)
        signUpButton.setTitleColor(.white, for: .normal)
        signUpButton.titleLabel?.font = AppFont.semibold(size: 18)
        signUpButton.backgroundColor = UIColor(red: 0.28, green: 0.02, blue: 0.01, alpha: 1.0)
        signUpButton.layer.cornerRadius = Constants.buttonHeight / 2
        signUpButton.accessibilityIdentifier = "signUpButton"
        signUpButton.addTarget(self, action: #selector(handleSignUpTapped), for: .touchUpInside)
    }

    private func configureLayout() {
        view.addSubview(titleLabel)
        view.addSubview(emailField)
        view.addSubview(passwordField)
        view.addSubview(confirmPasswordField)
        view.addSubview(signUpButton)

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

            signUpButton.topAnchor.constraint(equalTo: confirmPasswordField.bottomAnchor, constant: 88),
            signUpButton.leadingAnchor.constraint(equalTo: emailField.leadingAnchor, constant: 25),
            signUpButton.trailingAnchor.constraint(equalTo: emailField.trailingAnchor, constant: -25),
            signUpButton.heightAnchor.constraint(equalToConstant: Constants.buttonHeight)
        ])
    }

    @objc private func handleBackButtonTapped() {
        navigationController?.popViewController(animated: true)
    }

    @objc private func handleSignUpTapped() {
        switch viewModel.makeRegistrationDraft(
            email: emailField.text,
            password: passwordField.text,
            confirmPassword: confirmPasswordField.text
        ) {
        case .success(let draft):
            navigationController?.pushViewController(PersonalInfoViewController(registrationDraft: draft), animated: true)
        case .failure(let error):
            showToast(message: error.message)
        }
    }

    private func showToast(message: String) {
        AppToast.show(
            message: message,
            in: view,
            relation: .below(signUpButton.bottomAnchor, spacing: 18),
            accessibilityIdentifier: "signUpToastLabel"
        )
    }
}
