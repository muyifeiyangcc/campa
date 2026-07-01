import AuthenticationServices
import UIKit

final class AuthEntryViewController: UIViewController {
    private enum Constants {
        static let horizontalInset: CGFloat = 48
        static let primaryButtonHeight: CGFloat = 56
        static let logoSize: CGFloat = 74
    }

    private let viewModel: AuthEntryViewModel
    private let logoImageView = UIImageView()
    private let appNameLabel = UILabel()
    private let loginByEmailButton = UIButton(type: .system)
    private let newUserButton = UIButton(type: .system)
    private let signUpButton = UIButton(type: .system)
    private let dividerStackView = UIStackView()
    private let leftDividerView = UIView()
    private let otherLoginMethodsLabel = UILabel()
    private let rightDividerView = UIView()
    private let appleButton = UIButton(type: .system)
    private let agreementStackView = UIStackView()
    private let agreementButton = UIButton(type: .custom)
    private let agreementLabel = UILabel()
    private let userAgreementText = NSLocalizedString("User Agreement", comment: "User agreement link")
    private let privacyPolicyText = NSLocalizedString("Privacy Policy", comment: "Privacy policy link")
    private let signUpText = NSLocalizedString("Sign up", comment: "Sign up link")
    private var isAgreementSelected = false
    private let userRepository: UserRepository

    init(viewModel: AuthEntryViewModel = AuthEntryViewModel(), userRepository: UserRepository = UserRepository()) {
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

        configureView()
        configureLogo()
        configureAppNameLabel()
        configureButtons()
        configureDivider()
        configureAgreement()
        configureLayout()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    private func configureView() {
        view.backgroundColor = UIColor(red: 0.98, green: 0.93, blue: 0.86, alpha: 1.0)
    }

    private func configureLogo() {
        logoImageView.translatesAutoresizingMaskIntoConstraints = false
        logoImageView.image = UIImage(named: "logo")
        logoImageView.contentMode = .scaleAspectFit
        logoImageView.accessibilityIdentifier = "authEntryLogoImageView"
    }

    private func configureAppNameLabel() {
        appNameLabel.translatesAutoresizingMaskIntoConstraints = false
        appNameLabel.text = viewModel.appName
        appNameLabel.font = AppFont.semibold(size: 30)
        appNameLabel.textColor = UIColor(red: 0.25, green: 0.12, blue: 0.08, alpha: 1.0)
        appNameLabel.textAlignment = .center
    }

    private func configureButtons() {
        configureFilledButton(
            loginByEmailButton,
            title: viewModel.loginByEmailTitle,
            backgroundColor: UIColor(red: 0.28, green: 0.02, blue: 0.01, alpha: 1.0),
            titleColor: .white
        )
        loginByEmailButton.accessibilityIdentifier = "loginByEmailButton"
        loginByEmailButton.addTarget(self, action: #selector(handleLoginByEmailTapped), for: .touchUpInside)

        configureFilledButton(
            newUserButton,
            title: viewModel.newUserTitle,
            backgroundColor: UIColor(red: 0.69, green: 0.59, blue: 0.96, alpha: 1.0),
            titleColor: UIColor(red: 0.28, green: 0.02, blue: 0.01, alpha: 1.0)
        )
        newUserButton.accessibilityIdentifier = "newUserButton"
        newUserButton.addTarget(self, action: #selector(handleNewUserTapped), for: .touchUpInside)

        signUpButton.translatesAutoresizingMaskIntoConstraints = false
        signUpButton.setAttributedTitle(makeSignUpAttributedText(), for: .normal)
        signUpButton.titleLabel?.font = AppFont.regular(size: 11)
        signUpButton.accessibilityIdentifier = "signUpPromptButton"
        signUpButton.addTarget(self, action: #selector(handleSignUpPromptTapped), for: .touchUpInside)

        appleButton.translatesAutoresizingMaskIntoConstraints = false
        appleButton.backgroundColor = UIColor(red: 0.13, green: 0.15, blue: 0.16, alpha: 1.0)
        appleButton.layer.cornerRadius = 22
        appleButton.setImage(UIImage(named: "apple"), for: .normal)
        appleButton.tintColor = .white
        appleButton.accessibilityIdentifier = "appleLoginButton"
        appleButton.addTarget(self, action: #selector(handleAppleButtonTapped), for: .touchUpInside)
    }

    private func configureFilledButton(
        _ button: UIButton,
        title: String,
        backgroundColor: UIColor,
        titleColor: UIColor
    ) {
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle(title, for: .normal)
        button.setTitleColor(titleColor, for: .normal)
        button.titleLabel?.font = AppFont.semibold(size: 16)
        button.backgroundColor = backgroundColor
        button.layer.cornerRadius = Constants.primaryButtonHeight / 2
    }

    private func configureDivider() {
        dividerStackView.translatesAutoresizingMaskIntoConstraints = false
        dividerStackView.axis = .horizontal
        dividerStackView.alignment = .center
        dividerStackView.spacing = 8

        [leftDividerView, rightDividerView].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            $0.backgroundColor = UIColor(red: 0.55, green: 0.47, blue: 0.39, alpha: 0.35)
        }

        otherLoginMethodsLabel.translatesAutoresizingMaskIntoConstraints = false
        otherLoginMethodsLabel.text = viewModel.otherLoginMethodsTitle
        otherLoginMethodsLabel.font = AppFont.regular(size: 10)
        otherLoginMethodsLabel.textColor = UIColor(red: 0.44, green: 0.34, blue: 0.28, alpha: 1.0)
        otherLoginMethodsLabel.textAlignment = .center

        dividerStackView.addArrangedSubview(leftDividerView)
        dividerStackView.addArrangedSubview(otherLoginMethodsLabel)
        dividerStackView.addArrangedSubview(rightDividerView)
    }

    private func configureAgreement() {
        agreementStackView.translatesAutoresizingMaskIntoConstraints = false
        agreementStackView.axis = .horizontal
        agreementStackView.alignment = .center
        agreementStackView.spacing = 6

        agreementButton.translatesAutoresizingMaskIntoConstraints = false
        agreementButton.setImage(UIImage(named: "un_select"), for: .normal)
        agreementButton.setImage(UIImage(named: "select"), for: .selected)
        agreementButton.imageView?.contentMode = .scaleAspectFit
        agreementButton.accessibilityIdentifier = "agreementButton"
        agreementButton.addTarget(self, action: #selector(handleAgreementButtonTapped), for: .touchUpInside)

        agreementLabel.translatesAutoresizingMaskIntoConstraints = false
        agreementLabel.attributedText = makeAgreementAttributedText()
        agreementLabel.font = AppFont.regular(size: 10)
        agreementLabel.textColor = UIColor(red: 0.24, green: 0.20, blue: 0.18, alpha: 1.0)
        agreementLabel.numberOfLines = 1
        agreementLabel.adjustsFontSizeToFitWidth = true
        agreementLabel.minimumScaleFactor = 0.75
        agreementLabel.isUserInteractionEnabled = true
        agreementLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleAgreementLabelTapped(_:))))

        agreementStackView.addArrangedSubview(agreementButton)
        agreementStackView.addArrangedSubview(agreementLabel)
    }

    private func configureLayout() {
        view.addSubview(logoImageView)
        view.addSubview(appNameLabel)
        view.addSubview(loginByEmailButton)
        view.addSubview(newUserButton)
        view.addSubview(signUpButton)
        view.addSubview(dividerStackView)
        view.addSubview(appleButton)
        view.addSubview(agreementStackView)

        NSLayoutConstraint.activate([
            logoImageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 92),
            logoImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            logoImageView.widthAnchor.constraint(equalToConstant: Constants.logoSize),
            logoImageView.heightAnchor.constraint(equalTo: logoImageView.widthAnchor),

            appNameLabel.topAnchor.constraint(equalTo: logoImageView.bottomAnchor, constant: 14),
            appNameLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            loginByEmailButton.topAnchor.constraint(equalTo: appNameLabel.bottomAnchor, constant: 84),
            loginByEmailButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: Constants.horizontalInset),
            loginByEmailButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -Constants.horizontalInset),
            loginByEmailButton.heightAnchor.constraint(equalToConstant: Constants.primaryButtonHeight),

            newUserButton.topAnchor.constraint(equalTo: loginByEmailButton.bottomAnchor, constant: 18),
            newUserButton.leadingAnchor.constraint(equalTo: loginByEmailButton.leadingAnchor),
            newUserButton.trailingAnchor.constraint(equalTo: loginByEmailButton.trailingAnchor),
            newUserButton.heightAnchor.constraint(equalToConstant: Constants.primaryButtonHeight),

            signUpButton.topAnchor.constraint(equalTo: newUserButton.bottomAnchor, constant: 22),
            signUpButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            dividerStackView.topAnchor.constraint(equalTo: signUpButton.bottomAnchor, constant: 20),
            dividerStackView.leadingAnchor.constraint(equalTo: loginByEmailButton.leadingAnchor),
            dividerStackView.trailingAnchor.constraint(equalTo: loginByEmailButton.trailingAnchor),
            leftDividerView.heightAnchor.constraint(equalToConstant: 1),
            rightDividerView.heightAnchor.constraint(equalToConstant: 1),
            leftDividerView.widthAnchor.constraint(equalTo: rightDividerView.widthAnchor),

            appleButton.topAnchor.constraint(equalTo: dividerStackView.bottomAnchor, constant: 20),
            appleButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            appleButton.widthAnchor.constraint(equalToConstant: 44),
            appleButton.heightAnchor.constraint(equalTo: appleButton.widthAnchor),

            agreementStackView.leadingAnchor.constraint(greaterThanOrEqualTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 30),
            agreementStackView.trailingAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -30),
            agreementStackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            agreementStackView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -28),
            agreementButton.widthAnchor.constraint(equalToConstant: 24),
            agreementButton.heightAnchor.constraint(equalTo: agreementButton.widthAnchor)
        ])
    }

    @objc private func handleLoginByEmailTapped() {
        guard guardAgreementSelected() else {
            return
        }

        navigationController?.pushViewController(LoginViewController(), animated: true)
    }

    @objc private func handleAgreementButtonTapped() {
        isAgreementSelected.toggle()
        agreementButton.isSelected = isAgreementSelected
    }

    @objc private func handleAgreementLabelTapped(_ gesture: UITapGestureRecognizer) {
        if agreementLabel.didTapAttributedText(userAgreementText, gesture: gesture) {
            handleUserAgreementTapped()
        } else if agreementLabel.didTapAttributedText(privacyPolicyText, gesture: gesture) {
            handlePrivacyPolicyTapped()
        }
    }

    private func handleUserAgreementTapped() {
        let viewController = WebViewController()
        viewController.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(viewController, animated: true)
    }

    private func handlePrivacyPolicyTapped() {
        let viewController = WebViewController()
        viewController.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(viewController, animated: true)
    }

    @objc private func handleNewUserTapped() {
        guard guardAgreementSelected() else {
            return
        }
        guard let user = loginGuestUser() else {
            showToast(message: NSLocalizedString("Failed to login", comment: "Guest login failed toast"))
            return
        }

        UserDefaults.standard.set(user.id.uuidString, forKey: CurrentUserIdKey)
        AppLoading.show(in: self.view) { [weak self] in
            guard let self = self else { return }
            self.switchToMainTabBarController()
        }
    }

    private func loginGuestUser() -> User? {
        if let userIdString = UserDefaults.standard.string(forKey: GuestUserIdKey),
           let userId = UUID(uuidString: userIdString),
           case .success(let user) = userRepository.fetchUser(id: userId),
           case .success(let activatedUser) = userRepository.activateUser(user) {
            return activatedUser
        }

        guard case .success(let user) = userRepository.createGuestCurrentUser() else {
            return nil
        }

        UserDefaults.standard.set(user.id.uuidString, forKey: GuestUserIdKey)
        return user
    }

    private func switchToMainTabBarController() {
        guard let window = view.window else {
            return
        }

        window.rootViewController = MainTabBarController()
        window.makeKeyAndVisible()
    }

    @objc private func handleSignUpPromptTapped() {
        navigationController?.pushViewController(SignUpViewController(), animated: true)
    }

    @objc private func handleAppleButtonTapped() {
        guard guardAgreementSelected() else {
            return
        }

        let provider = ASAuthorizationAppleIDProvider()
        let request = provider.createRequest()
        request.requestedScopes = [.fullName, .email]

        let authorizationController = ASAuthorizationController(authorizationRequests: [request])
        authorizationController.delegate = self
        authorizationController.presentationContextProvider = self
        authorizationController.performRequests()
    }

    private func guardAgreementSelected() -> Bool {
        guard isAgreementSelected else {
            showToast(message: NSLocalizedString("Please agree first", comment: "Agreement required toast"))
            return false
        }

        return true
    }

    private func makeAgreementAttributedText() -> NSAttributedString {
        let fullText = viewModel.agreementTitle
        let attributedString = NSMutableAttributedString(
            string: fullText,
            attributes: [
                .font: AppFont.regular(size: 10),
                .foregroundColor: UIColor(red: 0.24, green: 0.20, blue: 0.18, alpha: 1.0)
            ]
        )

        [userAgreementText, privacyPolicyText].forEach { linkText in
            let range = (fullText as NSString).range(of: linkText)
            guard range.location != NSNotFound else {
                return
            }

            attributedString.addAttributes(
                [
                    .underlineStyle: NSUnderlineStyle.single.rawValue,
                    .foregroundColor: UIColor(red: 0.24, green: 0.20, blue: 0.18, alpha: 1.0)
                ],
                range: range
            )
        }

        return attributedString
    }

    private func makeSignUpAttributedText() -> NSAttributedString {
        let fullText = viewModel.signUpPrompt
        let textColor = UIColor(red: 0.27, green: 0.18, blue: 0.14, alpha: 1.0)
        let attributedString = NSMutableAttributedString(
            string: fullText,
            attributes: [
                .font: AppFont.regular(size: 11),
                .foregroundColor: textColor
            ]
        )
        let range = (fullText as NSString).range(of: signUpText)
        guard range.location != NSNotFound else {
            return attributedString
        }

        attributedString.addAttributes(
            [
                .underlineStyle: NSUnderlineStyle.single.rawValue,
                .foregroundColor: textColor
            ],
            range: range
        )
        return attributedString
    }

    private func showToast(message: String) {
        AppToast.show(
            message: message,
            in: view,
            relation: .above(agreementStackView.topAnchor, spacing: 24),
            minWidth: 150,
            accessibilityIdentifier: "agreementToastLabel"
        )
    }
}

extension AuthEntryViewController: ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithAuthorization authorization: ASAuthorization
    ) {
        guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            return
        }
        
        UserDefaults.standard.set(credential.user, forKey: CurrentUserIdKey)
        AppLoading.show(in: self.view) { [weak self] in
            guard let self = self else { return }
            self.switchToMainTabBarController()
        }
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        let authorizationError = error as? ASAuthorizationError
        guard authorizationError?.code != .canceled else {
            return
        }

        showToast(message: NSLocalizedString("Apple login failed", comment: "Apple login failure toast"))
    }

    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        view.window ?? ASPresentationAnchor()
    }
}

private extension UILabel {
    func didTapAttributedText(_ targetText: String, gesture: UITapGestureRecognizer) -> Bool {
        guard let attributedText = attributedText, !targetText.isEmpty else {
            return false
        }

        let fullText = attributedText.string as NSString
        let targetRange = fullText.range(of: targetText)
        guard targetRange.location != NSNotFound else {
            return false
        }

        let layoutManager = NSLayoutManager()
        let textContainer = NSTextContainer(size: bounds.size)
        let textStorage = NSTextStorage(attributedString: attributedText)

        layoutManager.addTextContainer(textContainer)
        textStorage.addLayoutManager(layoutManager)

        textContainer.lineFragmentPadding = 0
        textContainer.maximumNumberOfLines = numberOfLines
        textContainer.lineBreakMode = lineBreakMode

        let location = gesture.location(in: self)
        let textBoundingBox = layoutManager.usedRect(for: textContainer)
        let textOffset = CGPoint(
            x: (bounds.width - textBoundingBox.width) * 0.5 - textBoundingBox.minX,
            y: (bounds.height - textBoundingBox.height) * 0.5 - textBoundingBox.minY
        )
        let textLocation = CGPoint(x: location.x - textOffset.x, y: location.y - textOffset.y)
        let characterIndex = layoutManager.characterIndex(
            for: textLocation,
            in: textContainer,
            fractionOfDistanceBetweenInsertionPoints: nil
        )

        return NSLocationInRange(characterIndex, targetRange)
    }
}
