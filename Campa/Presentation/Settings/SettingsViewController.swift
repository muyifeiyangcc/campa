import UIKit

final class SettingsViewController: BaseViewController {
    fileprivate enum Constants {
        static let horizontalInset: CGFloat = 22
        static let rowHeight: CGFloat = 44
        static let buttonHeight: CGFloat = 62
    }

    private let viewModel: SettingsViewModel
    private let userRepository: UserRepository
    private let rowsStackView = UIStackView()
    private let deleteAccountButton = UIButton(type: .custom)
    private let logOutButton = UIButton(type: .custom)

    init(viewModel: SettingsViewModel = SettingsViewModel(), userRepository: UserRepository = UserRepository()) {
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

        configureNavigation()
        configureRows()
        configureButtons()
        configureLayout()
    }

    private func configureNavigation() {
        view.backgroundColor = UIColor(red: 0.97, green: 0.93, blue: 0.87, alpha: 1.0)
        changeNavbar(.back)
    }

    private func configureRows() {
        rowsStackView.translatesAutoresizingMaskIntoConstraints = false
        rowsStackView.axis = .vertical
        rowsStackView.spacing = 0

        viewModel.rows
            .enumerated()
            .map { index, row in
                let rowView = SettingsPlainRowView(row: row)
                rowView.tag = index
                rowView.addTarget(self, action: #selector(handleRowTapped(_:)), for: .touchUpInside)
                return rowView
            }
            .forEach(rowsStackView.addArrangedSubview)

        view.addSubview(rowsStackView)
    }

    private func configureButtons() {
        configureActionButton(
            deleteAccountButton,
            title: viewModel.deleteAccountTitle,
            backgroundColor: UIColor(red: 0.72, green: 0.62, blue: 0.97, alpha: 1.0)
        )
        configureActionButton(
            logOutButton,
            title: viewModel.logOutTitle,
            backgroundColor: UIColor(red: 0.86, green: 0.90, blue: 0.12, alpha: 1.0)
        )

        view.addSubview(deleteAccountButton)
        view.addSubview(logOutButton)
        deleteAccountButton.addTarget(self, action: #selector(clickdDeleteAction), for: .touchUpInside)
        logOutButton.addTarget(self, action: #selector(clickLogoutAction), for: .touchUpInside)

    }
    
    @objc func clickdDeleteAction() {
        let vc = DeleteUserAlertController()
        vc.modalPresentationStyle = .overFullScreen
        vc.actionHandler = { [weak self] in
            self?.deleteCurrentUser()
        }
        self.present(vc, animated: false)
    }

    @objc private func handleRowTapped(_ sender: UIControl) {
        switch sender.tag {
        case 0:
            let vc = EditProfileViewController()
            vc.hidesBottomBarWhenPushed = true
            navigationController?.pushViewController(vc, animated: true)
        case 1:
            let vc = BlacklistViewController()
            vc.hidesBottomBarWhenPushed = true
            navigationController?.pushViewController(vc, animated: true)
        case 2:
            let vc = WalletViewController()
            vc.hidesBottomBarWhenPushed = true
            navigationController?.pushViewController(vc, animated: true)
        case 3:
            let vc = WebViewController()
            vc.type = .userAgreement
            vc.hidesBottomBarWhenPushed = true
            navigationController?.pushViewController(vc, animated: true)
        case 4:
            let vc = WebViewController()
            vc.type = .privacyPolicy
            vc.hidesBottomBarWhenPushed = true
            navigationController?.pushViewController(vc, animated: true)
        default:
            return
        }
    }

    private func deleteCurrentUser() {
        let userResult = userRepository.fetchCurrentUser()
        guard case .success(let user) = userResult,
              let email = user.email?.trimmingCharacters(in: .whitespacesAndNewlines),
              !email.isEmpty else {
            showToast(message: NSLocalizedString("Failed to delete account", comment: "Delete account failed toast"))
            return
        }

        switch userRepository.deleteUser(email: email) {
        case .success:
            AppLoading.show(in: self.view) { [weak self] in
                guard let self = self else { return }
                UserDefaults.standard.removeObject(forKey: GuestUserIdKey)
                UserDefaults.standard.set("", forKey: CurrentUserIdKey)
                UserDefaults.standard.synchronize()
                showToast(message: NSLocalizedString("Account deleted successfully", comment: "Delete account success toast"))
                guard let window = view.window else { return }
                window.rootViewController = UINavigationController(rootViewController: AuthEntryViewController())
                window.makeKeyAndVisible()
            }
        case .failure:
            showToast(message: NSLocalizedString("Failed to delete account", comment: "Delete account failed toast"))
        }
    }
    
    @objc func clickLogoutAction() {
        AppLoading.show(in: self.view) { [weak self] in
            guard let self = self else { return }
            UserDefaults.standard.set("", forKey: CurrentUserIdKey)
            UserDefaults.standard.synchronize()
            guard let window = view.window else { return }
            window.rootViewController = UINavigationController(rootViewController: AuthEntryViewController())
            window.makeKeyAndVisible()
        }
    }

    private func configureActionButton(_ button: UIButton, title: String, backgroundColor: UIColor) {
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle(title, for: .normal)
        button.setTitleColor(UIColor(red: 0.28, green: 0.02, blue: 0.02, alpha: 1.0), for: .normal)
        button.titleLabel?.font = AppFont.semibold(size: 18)
        button.backgroundColor = backgroundColor
        button.layer.cornerRadius = Constants.buttonHeight / 2
    }

    private func showToast(message: String) {
        AppToast.show(
            message: message,
            in: view,
            relation: .above(deleteAccountButton.topAnchor, spacing: 18),
            accessibilityIdentifier: "settingsToastLabel"
        )
    }

    private func configureLayout() {
        NSLayoutConstraint.activate([
            rowsStackView.topAnchor.constraint(equalTo: navBar.bottomAnchor, constant: 12),
            rowsStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: Constants.horizontalInset),
            rowsStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -Constants.horizontalInset),

            deleteAccountButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 33),
            deleteAccountButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -33),
            deleteAccountButton.heightAnchor.constraint(equalToConstant: Constants.buttonHeight),

            logOutButton.topAnchor.constraint(equalTo: deleteAccountButton.bottomAnchor, constant: 14),
            logOutButton.leadingAnchor.constraint(equalTo: deleteAccountButton.leadingAnchor),
            logOutButton.trailingAnchor.constraint(equalTo: deleteAccountButton.trailingAnchor),
            logOutButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -28),
            logOutButton.heightAnchor.constraint(equalToConstant: Constants.buttonHeight)
        ])
    }
}

private final class SettingsPlainRowView: UIControl {
    private let titleLabel = UILabel()
    private let arrowImageView = UIImageView()

    init(row: SettingsRow) {
        super.init(frame: .zero)

        configure(row: row)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }

    private func configure(row: SettingsRow) {
        translatesAutoresizingMaskIntoConstraints = false

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = row.title
        titleLabel.font = AppFont.semibold(size: 16)
        titleLabel.textColor = UIColor(red: 0.28, green: 0.02, blue: 0.02, alpha: 1.0)

        arrowImageView.translatesAutoresizingMaskIntoConstraints = false
        arrowImageView.image = UIImage(systemName: "chevron.right.circle")
        arrowImageView.tintColor = UIColor(red: 0.28, green: 0.02, blue: 0.02, alpha: 1.0)
        arrowImageView.contentMode = .scaleAspectFit

        addSubview(titleLabel)
        addSubview(arrowImageView)

        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: SettingsViewController.Constants.rowHeight),

            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: arrowImageView.leadingAnchor, constant: -12),

            arrowImageView.trailingAnchor.constraint(equalTo: trailingAnchor),
            arrowImageView.centerYAnchor.constraint(equalTo: centerYAnchor),
            arrowImageView.widthAnchor.constraint(equalToConstant: 18),
            arrowImageView.heightAnchor.constraint(equalToConstant: 18)
        ])
    }
}
