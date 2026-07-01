import Darwin
import UIKit

enum EULAAgreementStore {
    private static let acceptedKey = "hasAcceptedEULA"

    static var isAccepted: Bool {
        UserDefaults.standard.bool(forKey: acceptedKey)
    }

    static func accept() {
        UserDefaults.standard.set(true, forKey: acceptedKey)
    }
}

final class EULAViewController: BaseViewController {
    private enum Constants {
        static let horizontalInset: CGFloat = 20
        static let buttonHeight: CGFloat = 48
    }

    private let titleLabel = UILabel()
    private let scrollView = UIScrollView()
    private let contentStackView = UIStackView()
    private let introLabel = UILabel()
    private let actionStackView = UIStackView()
    private let cancelButton = UIButton(type: .custom)
    private let agreeButton = UIButton(type: .custom)
    private let agreementStackView = UIStackView()
    private let agreementButton = UIButton(type: .custom)
    private let agreementLabel = UILabel()
    private let userAgreementText = NSLocalizedString("User Agreement", comment: "User agreement link")
    private let privacyPolicyText = NSLocalizedString("Privacy Policy", comment: "Privacy policy link")
    private var isAgreementSelected = true

    override func viewDidLoad() {
        super.viewDidLoad()

        configureNavigation()
        configureContent()
        configureActions()
        configureAgreement()
        configureLayout()
        updateAgreementState()
    }

    // MARK: - Configuration

    private func configureNavigation() {
        navType = .back

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = NSLocalizedString("EULA", comment: "EULA screen title")
        titleLabel.font = AppFont.medium(size: 18)
        titleLabel.textColor = UIColor(red: 0.25, green: 0.20, blue: 0.17, alpha: 1.0)
        titleLabel.textAlignment = .center

        navBar.addSubview(titleLabel)
        NSLayoutConstraint.activate([
            titleLabel.centerXAnchor.constraint(equalTo: navBar.centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: navBar.centerYAnchor)
        ])
    }

    private func configureContent() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.alwaysBounceVertical = true

        contentStackView.translatesAutoresizingMaskIntoConstraints = false
        contentStackView.axis = .vertical
        contentStackView.spacing = 14

        introLabel.translatesAutoresizingMaskIntoConstraints = false
        introLabel.attributedText = makeBodyText()
        introLabel.numberOfLines = 0
        introLabel.textColor = UIColor(red: 0.31, green: 0.25, blue: 0.22, alpha: 1.0)
        introLabel.font = AppFont.regular(size: 12)
    }

    private func configureActions() {
        actionStackView.translatesAutoresizingMaskIntoConstraints = false
        actionStackView.axis = .horizontal
        actionStackView.distribution = .fillEqually
        actionStackView.spacing = 24

        configureFilledButton(
            cancelButton,
            title: NSLocalizedString("Cancel", comment: "EULA cancel button"),
            backgroundColor: UIColor(red: 0.28, green: 0.02, blue: 0.01, alpha: 1.0),
            titleColor: .white
        )
        configureFilledButton(
            agreeButton,
            title: NSLocalizedString("I agree", comment: "EULA agree button"),
            backgroundColor: UIColor(red: 0.69, green: 0.59, blue: 0.96, alpha: 1.0),
            titleColor: UIColor(red: 0.18, green: 0.10, blue: 0.08, alpha: 1.0)
        )

        cancelButton.addTarget(self, action: #selector(handleCancelTapped), for: .touchUpInside)
        agreeButton.addTarget(self, action: #selector(handleAgreeTapped), for: .touchUpInside)
    }

    private func configureAgreement() {
        agreementStackView.translatesAutoresizingMaskIntoConstraints = false
        agreementStackView.axis = .horizontal
        agreementStackView.alignment = .center
        agreementStackView.spacing = 5

        agreementButton.translatesAutoresizingMaskIntoConstraints = false
        agreementButton.setImage(UIImage(named: "un_select"), for: .normal)
        agreementButton.setImage(UIImage(named: "select"), for: .selected)
        agreementButton.imageView?.contentMode = .scaleAspectFit
        agreementButton.addTarget(self, action: #selector(handleAgreementTapped), for: .touchUpInside)

        agreementLabel.translatesAutoresizingMaskIntoConstraints = false
        agreementLabel.attributedText = makeAgreementText()
        agreementLabel.numberOfLines = 1
        agreementLabel.adjustsFontSizeToFitWidth = true
        agreementLabel.minimumScaleFactor = 0.75
        agreementLabel.isUserInteractionEnabled = true
        agreementLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleAgreementLabelTapped(_:))))
    }

    private func configureLayout() {
        view.addSubview(scrollView)
        view.addSubview(actionStackView)
        view.addSubview(agreementStackView)

        scrollView.addSubview(contentStackView)
        contentStackView.addArrangedSubview(introLabel)

        actionStackView.addArrangedSubview(cancelButton)
        actionStackView.addArrangedSubview(agreeButton)

        agreementStackView.addArrangedSubview(agreementButton)
        agreementStackView.addArrangedSubview(agreementLabel)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: navBar.bottomAnchor, constant: 10),
            scrollView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: Constants.horizontalInset),
            scrollView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -Constants.horizontalInset),
            scrollView.bottomAnchor.constraint(equalTo: actionStackView.topAnchor, constant: -18),

            contentStackView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            contentStackView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            contentStackView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            contentStackView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            contentStackView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),

            actionStackView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 48),
            actionStackView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -48),
            actionStackView.bottomAnchor.constraint(equalTo: agreementStackView.topAnchor, constant: -22),
            actionStackView.heightAnchor.constraint(equalToConstant: Constants.buttonHeight),

            agreementStackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            agreementStackView.leadingAnchor.constraint(greaterThanOrEqualTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 24),
            agreementStackView.trailingAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -24),
            agreementStackView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            agreementButton.widthAnchor.constraint(equalToConstant: 20),
            agreementButton.heightAnchor.constraint(equalTo: agreementButton.widthAnchor)
        ])
    }

    // MARK: - Actions

    @objc private func handleTermsTapped() {
        openWebView(type: .userAgreement)
    }

    @objc private func handlePrivacyTapped() {
        openWebView(type: .privacyPolicy)
    }

    @objc private func handleCancelTapped() {
        exit(0)
    }

    @objc private func handleAgreeTapped() {
        guard isAgreementSelected else {
            AppToast.show(message: NSLocalizedString("Please agree first", comment: "Agreement required toast"), in: view)
            return
        }

        EULAAgreementStore.accept()
        navigationController?.popViewController(animated: true)
    }

    @objc private func handleAgreementTapped() {
        isAgreementSelected.toggle()
        updateAgreementState()
    }

    @objc private func handleAgreementLabelTapped(_ gesture: UITapGestureRecognizer) {
        if agreementLabel.didTapAttributedText(userAgreementText, gesture: gesture) {
            openWebView(type: .userAgreement)
        } else if agreementLabel.didTapAttributedText(privacyPolicyText, gesture: gesture) {
            openWebView(type: .privacyPolicy)
        }
    }

    // MARK: - Private Methods

    private func openWebView(type: LinkType) {
        let viewController = WebViewController()
        viewController.type = type
        viewController.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(viewController, animated: true)
    }

    private func updateAgreementState() {
        agreementButton.isSelected = isAgreementSelected
        agreeButton.isEnabled = isAgreementSelected
        agreeButton.alpha = isAgreementSelected ? 1.0 : 0.55
    }

    private func configureLinkButton(_ button: UIButton, title: String) {
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setAttributedTitle(
            NSAttributedString(
                string: title,
                attributes: [
                    .font: AppFont.medium(size: 11),
                    .foregroundColor: UIColor(red: 0.20, green: 0.12, blue: 0.09, alpha: 1.0),
                    .underlineStyle: NSUnderlineStyle.single.rawValue
                ]
            ),
            for: .normal
        )
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
        button.titleLabel?.font = AppFont.semibold(size: 13)
        button.backgroundColor = backgroundColor
        button.layer.cornerRadius = Constants.buttonHeight / 2
    }

    private func makeAgreementText() -> NSAttributedString {
        let fullText = NSLocalizedString(
            "Agree with User Agreement and Privacy Policy",
            comment: "EULA agreement checkbox text"
        )
        let attributedString = NSMutableAttributedString(
            string: fullText,
            attributes: [
                .font: AppFont.medium(size: 10),
                .foregroundColor: UIColor(red: 0.22, green: 0.16, blue: 0.13, alpha: 1.0)
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
                    .foregroundColor: UIColor(red: 0.16, green: 0.09, blue: 0.07, alpha: 1.0)
                ],
                range: range
            )
        }

        return attributedString
    }

    private func makeBodyText() -> NSAttributedString {
        let bodyText = "This End User License Agreement (“Agreement”) governs your use of the Campa  Application (“App”). By downloading, accessing, registering or using the App, you agree to be bound by this Agreement. If you do not agree, you may not use the App.\n1. EligibilityYou confirm that you are a legitimate campus user (student or faculty) with full legal capacity and that all information you provide is true and accurate. Minors may only use the App with guardian consent. Falsifying identity or impersonating others will result in restricted or terminated access.\n2. User Generated ContentCampa allows users to post and share campus-related text, images and videos (“User Content”). By posting content, you agree to the terms below.\n2.1 Prohibited ContentYou may not post content that is offensive, harmful, inappropriate or illegal, including:\n- Harassment, insults, threats, discrimination or personal attacks;\n- Pornographic, vulgar or obscene material;\n- Content promoting violence, bullying, illegal activities or rule violations;\n- Content infringing others’ copyright, privacy or personal rights;\n- Unauthorized commercial ads, spam or off-campus irrelevant content;\n- False or misleading information.\n2.2 Content LicenseYou retain ownership of your User Content. You grant Campa a non-exclusive, royalty-free license to use, display, distribute and promote your content within the App for campus service operation purposes.\n3. Reporting & ModerationUsers shall report any violating content via the App’s built-in reporting tool. We will review reports within 24 hours and take measures including content removal, warnings, function restrictions or account suspension. Severe or repeated violations will lead to permanent account ban.\n4. Privacy PolicyYour use of the App confirms that you have read and agreed to our [Privacy Policy], which explains how we collect, use and protect your personal information and forms part of this Agreement.\n5. TerminationWe may suspend or terminate your account at any time, with or without notice, for violations of this Agreement or applicable laws. You may stop using the App and delete your account at any time.\n6. Agreement UpdatesWe may revise this Agreement from time to time. Updated terms will be posted in the App. Continued use after updates constitutes acceptance of the revised terms.\n7. DisclaimerThe App is provided on an “AS IS” and “AS AVAILABLE” basis. We do not warrant uninterrupted, error-free or secure service, nor the accuracy of user-generated content.\n8. Liability LimitationTo the fullest extent permitted by law, Campa shall not be liable for any direct or indirect damages arising from your use of the App or any user content-related disputes."

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 2
        paragraphStyle.paragraphSpacing = 5

        return NSAttributedString(
            string: bodyText,
            attributes: [
                .font: AppFont.regular(size: 12),
                .foregroundColor: UIColor(red: 0.31, green: 0.25, blue: 0.22, alpha: 1.0),
                .paragraphStyle: paragraphStyle
            ]
        )
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
