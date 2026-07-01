import UIKit

final class LoginViewController: BaseViewController {
    private enum Constants {
        static let horizontalInset: CGFloat = 30
        static let fieldHeight: CGFloat = 64
        static let buttonHeight: CGFloat = 62
        static let fieldCornerRadius: CGFloat = 40
    }

    private let viewModel: LoginViewModel
    private let titleLabel = UILabel()
    private let emailField = IconTextField(iconName: "email")
    private let passwordField = IconTextField(iconName: "password")
    private let forgotPasswordButton = UIButton(type: .system)
    private let loginButton = UIButton(type: .system)
    private let userRepository: UserRepository

    init(viewModel: LoginViewModel = LoginViewModel(), userRepository: UserRepository = UserRepository()) {
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

        configureTitleLabel()
        configureFields()
        configureForgotPasswordButton()
        configureLoginButton()
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
        emailField.textContentType = .username
        emailField.autocapitalizationType = .none
        emailField.accessibilityIdentifier = "loginEmailField"

        passwordField.translatesAutoresizingMaskIntoConstraints = false
        passwordField.placeholder = viewModel.passwordPlaceholder
        passwordField.textContentType = .password
        passwordField.isSecureTextEntry = true
        passwordField.accessibilityIdentifier = "loginPasswordField"
    }

    private func configureForgotPasswordButton() {
        forgotPasswordButton.translatesAutoresizingMaskIntoConstraints = false
        forgotPasswordButton.setTitle(viewModel.forgotPasswordTitle, for: .normal)
        forgotPasswordButton.setTitleColor(UIColor(red: 0.30, green: 0.20, blue: 0.16, alpha: 1.0), for: .normal)
        forgotPasswordButton.titleLabel?.font = AppFont.medium(size: 8)
        forgotPasswordButton.contentHorizontalAlignment = .right
        forgotPasswordButton.accessibilityIdentifier = "forgotPasswordButton"
        forgotPasswordButton.addTarget(self, action: #selector(handleForgotPasswordTapped), for: .touchUpInside)
    }

    private func configureLoginButton() {
        loginButton.translatesAutoresizingMaskIntoConstraints = false
        loginButton.setTitle(viewModel.loginButtonTitle, for: .normal)
        loginButton.setTitleColor(.white, for: .normal)
        loginButton.titleLabel?.font = AppFont.semibold(size: 18)
        loginButton.backgroundColor = UIColor(red: 0.28, green: 0.02, blue: 0.01, alpha: 1.0)
        loginButton.layer.cornerRadius = Constants.buttonHeight / 2
        loginButton.accessibilityIdentifier = "loginButton"
        loginButton.addTarget(self, action: #selector(handleLoginTapped), for: .touchUpInside)
    }

    private func configureLayout() {
        self.navType = .back
        view.addSubview(titleLabel)
        view.addSubview(emailField)
        view.addSubview(passwordField)
        view.addSubview(forgotPasswordButton)
        view.addSubview(loginButton)

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 74),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            emailField.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 74),
            emailField.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: Constants.horizontalInset),
            emailField.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -Constants.horizontalInset),
            emailField.heightAnchor.constraint(equalToConstant: Constants.fieldHeight),

            passwordField.topAnchor.constraint(equalTo: emailField.bottomAnchor, constant: 14),
            passwordField.leadingAnchor.constraint(equalTo: emailField.leadingAnchor),
            passwordField.trailingAnchor.constraint(equalTo: emailField.trailingAnchor),
            passwordField.heightAnchor.constraint(equalToConstant: Constants.fieldHeight),

            forgotPasswordButton.topAnchor.constraint(equalTo: passwordField.bottomAnchor, constant: 8),
            forgotPasswordButton.trailingAnchor.constraint(equalTo: passwordField.trailingAnchor, constant: -4),

            loginButton.topAnchor.constraint(equalTo: forgotPasswordButton.bottomAnchor, constant: 70),
            loginButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: Constants.buttonHeight),
            loginButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -Constants.buttonHeight),
            loginButton.heightAnchor.constraint(equalToConstant: Constants.buttonHeight)
        ])
    }

    @objc private func handleBackButtonTapped() {
        navigationController?.popViewController(animated: true)
    }

    @objc private func handleForgotPasswordTapped() {
        navigationController?.pushViewController(ForgotPasswordViewController(), animated: true)
    }

    @objc private func handleLoginTapped() {
        let email = emailField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let password = passwordField.text ?? ""

        guard !email.isEmpty, !password.isEmpty else {
            showToast(message: viewModel.emptyInputMessage)
            return
        }

        let result = userRepository.login(email: email, passwordHash: viewModel.hash(password))
        guard case .success(let user) = result else {
            showToast(message: viewModel.loginFailedMessage)
            return
        }

        UserDefaults.standard.set(user.id.uuidString, forKey: CurrentUserIdKey)
        AppLoading.show(in: self.view) { [weak self] in
            guard let self = self else { return }
            self.switchToMainTabBarController()
        }
    }

    private func switchToMainTabBarController() {
        guard let window = view.window else {
            return
        }

        window.rootViewController = MainTabBarController()
        window.makeKeyAndVisible()
    }

    private func showToast(message: String) {
        AppToast.show(
            message: message,
            in: view,
            relation: .above(loginButton.topAnchor, spacing: 18),
            accessibilityIdentifier: "loginToastLabel"
        )
    }
}

final class IconTextField: UITextField {
    private let iconView = UIImageView()

    init(iconName: String) {
        super.init(frame: .zero)

        configure(iconName: iconName)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }

    override func textRect(forBounds bounds: CGRect) -> CGRect {
        bounds.inset(by: UIEdgeInsets(top: 0, left: 44, bottom: 0, right: 16))
    }

    override func editingRect(forBounds bounds: CGRect) -> CGRect {
        textRect(forBounds: bounds)
    }

    override func placeholderRect(forBounds bounds: CGRect) -> CGRect {
        textRect(forBounds: bounds)
    }

    private func configure(iconName: String) {
        backgroundColor = UIColor(red: 0.69, green: 0.59, blue: 0.96, alpha: 1.0)
        layer.cornerRadius = 30
        clipsToBounds = true
        textColor = .white
        tintColor = .white
        font = AppFont.medium(size: 12)
        attributedPlaceholder = NSAttributedString(
            string: "",
            attributes: [
                .foregroundColor: UIColor.white.withAlphaComponent(0.45),
                .font: AppFont.medium(size: 12)
            ]
        )

        iconView.image = UIImage(named: iconName)
        iconView.contentMode = .scaleAspectFit
        iconView.tintColor = .white
        iconView.frame = CGRect(x: 0, y: 0, width: 24, height: 24)

        let iconContainer = UIView(frame: CGRect(x: 0, y: 0, width: 44, height: 36))
        iconView.center = CGPoint(x: 28, y: 18)
        iconContainer.addSubview(iconView)
        leftView = iconContainer
        leftViewMode = .always
    }

    override var placeholder: String? {
        didSet {
            guard let placeholder else {
                return
            }

            attributedPlaceholder = NSAttributedString(
                string: placeholder,
                attributes: [
                    .foregroundColor: UIColor.white.withAlphaComponent(0.45),
                    .font: AppFont.medium(size: 12)
                ]
            )
        }
    }
}
