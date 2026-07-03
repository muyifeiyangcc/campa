//
//  LoginAlertController.swift
//  Campa
//
//  Created by Codex on 2026/7/3.
//

import UIKit

final class LoginAlertController: UIViewController {
    private enum Metrics {
        static let buttonColor = UIColor(red: 52 / 255.0, green: 4 / 255.0, blue: 4 / 255.0, alpha: 1)
        static let loginColor = UIColor(red: 215 / 255.0, green: 220 / 255.0, blue: 56 / 255.0, alpha: 1)
        static let containerSize = CGSize(width: 284, height: 352)
        static let buttonHeight: CGFloat = 50
    }

    private let alertContainer: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let alertBgImgV: UIImageView = {
        let view = UIImageView()
        view.image = UIImage(named: "alert_bg")
        view.contentMode = .scaleToFill
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let lineView: UIImageView = {
        let view = UIImageView()
        view.image = UIImage(named: "line_pupor")
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let loginInfoImgV: UIImageView = {
        let view = UIImageView()
        view.image = UIImage(named: "login_info")
        view.contentMode = .scaleAspectFit
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let messageLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = Metrics.buttonColor
        label.textAlignment = .center
        label.numberOfLines = 0
        label.text = "To ensure the normal\noperation of the function,\nplease log in to your account\nfirst."
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let cancelButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setTitle("Cancel", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = Metrics.buttonColor
        button.layer.cornerRadius = Metrics.buttonHeight / 2
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private let loginButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setTitle("Log in", for: .normal)
        button.setTitleColor(.black, for: .normal)
        button.backgroundColor = Metrics.loginColor
        button.layer.cornerRadius = Metrics.buttonHeight / 2
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    init() {
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .overFullScreen
        modalTransitionStyle = .crossDissolve
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        configureHierarchy()
        configureConstraints()
        configureActions()
    }

    private func configureHierarchy() {
        view.addSubview(alertContainer)
        alertContainer.addSubview(alertBgImgV)
        alertContainer.addSubview(loginInfoImgV)
        alertContainer.addSubview(messageLabel)
        alertContainer.addSubview(cancelButton)
        alertContainer.addSubview(loginButton)
        alertContainer.addSubview(lineView)
    }

    private func configureConstraints() {
        NSLayoutConstraint.activate([
            alertContainer.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            alertContainer.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            alertContainer.widthAnchor.constraint(equalToConstant: Metrics.containerSize.width),
            alertContainer.heightAnchor.constraint(equalToConstant: Metrics.containerSize.height),

            alertBgImgV.leadingAnchor.constraint(equalTo: alertContainer.leadingAnchor),
            alertBgImgV.trailingAnchor.constraint(equalTo: alertContainer.trailingAnchor),
            alertBgImgV.topAnchor.constraint(equalTo: alertContainer.topAnchor),
            alertBgImgV.bottomAnchor.constraint(equalTo: alertContainer.bottomAnchor),

            lineView.topAnchor.constraint(equalTo: alertContainer.topAnchor, constant: -8),
            lineView.trailingAnchor.constraint(equalTo: alertContainer.trailingAnchor, constant: -6),

            loginInfoImgV.centerXAnchor.constraint(equalTo: alertContainer.centerXAnchor),
            loginInfoImgV.topAnchor.constraint(equalTo: alertContainer.topAnchor, constant: 18),
            loginInfoImgV.widthAnchor.constraint(equalToConstant: 71),
            loginInfoImgV.heightAnchor.constraint(equalToConstant: 71),

            messageLabel.leadingAnchor.constraint(equalTo: alertContainer.leadingAnchor, constant: 36),
            messageLabel.trailingAnchor.constraint(equalTo: alertContainer.trailingAnchor, constant: -36),
            messageLabel.topAnchor.constraint(equalTo: loginInfoImgV.bottomAnchor, constant: 1),

            cancelButton.leadingAnchor.constraint(equalTo: alertContainer.leadingAnchor, constant: 46),
            cancelButton.trailingAnchor.constraint(equalTo: alertContainer.trailingAnchor, constant: -46),
            cancelButton.topAnchor.constraint(equalTo: messageLabel.bottomAnchor, constant: 36),
            cancelButton.heightAnchor.constraint(equalToConstant: Metrics.buttonHeight),

            loginButton.leadingAnchor.constraint(equalTo: cancelButton.leadingAnchor),
            loginButton.trailingAnchor.constraint(equalTo: cancelButton.trailingAnchor),
            loginButton.topAnchor.constraint(equalTo: cancelButton.bottomAnchor, constant: 14),
            loginButton.heightAnchor.constraint(equalToConstant: Metrics.buttonHeight)
        ])
    }

    private func configureActions() {
        cancelButton.addTarget(self, action: #selector(clickCancelAction), for: .touchUpInside)
        loginButton.addTarget(self, action: #selector(clickLoginAction), for: .touchUpInside)
    }

    @objc private func clickCancelAction() {
        dismiss(animated: false)
    }

    @objc private func clickLoginAction() {
        let targetWindow = view.window ?? Self.keyWindow
        dismiss(animated: false) {
            Self.showAuthEntry(in: targetWindow)
        }
    }

    private static func showAuthEntry(in window: UIWindow?) {
        guard let window = window ?? keyWindow else {
            return
        }

        let authEntryController = UINavigationController(rootViewController: AuthEntryViewController())
        UIView.transition(with: window, duration: 0.25, options: .transitionCrossDissolve) {
            window.rootViewController = authEntryController
        }
    }

    private static var keyWindow: UIWindow? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first { $0.isKeyWindow }
    }
}
