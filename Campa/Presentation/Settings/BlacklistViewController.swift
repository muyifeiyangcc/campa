import UIKit

final class BlacklistViewController: BaseViewController {
    private enum Constants {
        static let rowHeight: CGFloat = 78
        static let tableTopInset: CGFloat = 20
        static let backgroundColor = UIColor(red: 0.97, green: 0.93, blue: 0.87, alpha: 1.0)
    }

    private let userRepository: UserRepository
    private let tableView = UITableView(frame: .zero, style: .plain)
    private var users: [User] = []
    private var currentUser: User?

    init(userRepository: UserRepository = UserRepository()) {
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
        configureTableView()
        configureLayout()
        loadBlockedUsers()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        tableView.backgroundView?.frame = tableView.bounds
    }

    private func configureNavigation() {
        view.backgroundColor = Constants.backgroundColor
        changeNavbar(.backTiltle)
        setTitleAndRight(title: NSLocalizedString("Blacklist", comment: "Blacklist title"), right: nil)
    }

    private func configureTableView() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.showsVerticalScrollIndicator = false
        tableView.rowHeight = Constants.rowHeight
        tableView.dataSource = self
        tableView.register(BlacklistTableViewCell.self, forCellReuseIdentifier: BlacklistTableViewCell.reuseIdentifier)

        view.addSubview(tableView)
    }

    private func configureLayout() {
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: navBar.bottomAnchor, constant: Constants.tableTopInset),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func loadBlockedUsers() {
        guard let currentUser = makeCurrentUser() else {
            users = []
            updateEmptyState()
            return
        }

        self.currentUser = currentUser
        switch userRepository.fetchBlockedUsers(for: currentUser) {
        case .success(let blockedUsers):
            users = blockedUsers
        case .failure:
            users = []
        }

        AppLoading.show(in: self.view) { [weak self] in
            guard let self = self else { return }
            self.tableView.reloadData()
            self.updateEmptyState()
        }
    }

    private func makeCurrentUser() -> User? {
        if let userIdString = UserDefaults.standard.string(forKey: CurrentUserIdKey),
           let userId = UUID(uuidString: userIdString),
           case .success(let user) = userRepository.fetchUser(id: userId) {
            return user
        }

        if case .success(let user) = userRepository.fetchCurrentUser() {
            return user
        }

        return nil
    }

    private func revokeBlock(user: User) {
        guard let currentUser else { return }

        switch userRepository.removeRelation(from: currentUser, to: user, type: .block) {
        case .success:
            users.removeAll { $0.objectID == user.objectID }
            tableView.reloadData()
            updateEmptyState()
        case .failure:
            break
        }
    }

    private func updateEmptyState() {
        tableView.backgroundView = users.isEmpty ? EmptyView(frame: tableView.bounds) : nil
        tableView.isScrollEnabled = !users.isEmpty
    }
}

extension BlacklistViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        users.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: BlacklistTableViewCell.reuseIdentifier,
            for: indexPath
        ) as? BlacklistTableViewCell else {
            return UITableViewCell()
        }

        let user = users[indexPath.row]
        cell.configure(user: user)
        cell.onRevokeTapped = { [weak self] in
            self?.revokeBlock(user: user)
        }
        return cell
    }
}

private final class BlacklistTableViewCell: UITableViewCell {
    static let reuseIdentifier = "BlacklistTableViewCell"

    private enum Constants {
        static let horizontalInset: CGFloat = 20
        static let containerInset: CGFloat = 8
        static let avatarSize: CGFloat = 48
        static let revokeButtonWidth: CGFloat = 94
        static let revokeButtonHeight: CGFloat = 38
        static let revokeColor = UIColor(red: 196 / 255.0, green: 187 / 255.0, blue: 254 / 255.0, alpha: 1.0)
    }

    private let containerView = UIView()
    private let avatarImageView = UIImageView()
    private let nameLabel = UILabel()
    private let revokeButton = UIButton(type: .custom)
    var onRevokeTapped: (() -> Void)?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        configureViews()
        configureLayout()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }

    func configure(user: User) {
        nameLabel.text = user.nickname
        onRevokeTapped = nil
        avatarImageView.image = UIImage.sandboxOrAssetImage(
            named: user.avatarLocalPath,
            documentsSubdirectory: "Avatars",
            fallbackName: "user_icon"
        )
    }

    private func configureViews() {
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        selectionStyle = .none

        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.backgroundColor = .white
        containerView.layer.cornerRadius = 18
        containerView.clipsToBounds = true

        avatarImageView.translatesAutoresizingMaskIntoConstraints = false
        avatarImageView.contentMode = .scaleAspectFill
        avatarImageView.layer.cornerRadius = Constants.avatarSize / 2
        avatarImageView.clipsToBounds = true

        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.textColor = UIColor(red: 0.20, green: 0.17, blue: 0.17, alpha: 1.0)
        nameLabel.font = AppFont.medium(size: 16)

        revokeButton.translatesAutoresizingMaskIntoConstraints = false
        revokeButton.backgroundColor = Constants.revokeColor
        revokeButton.layer.cornerRadius = Constants.revokeButtonHeight / 2
        revokeButton.setTitle(NSLocalizedString("Revocate", comment: "Revoke block action"), for: .normal)
        revokeButton.setTitleColor(UIColor(red: 0.28, green: 0.02, blue: 0.02, alpha: 1.0), for: .normal)
        revokeButton.titleLabel?.font = AppFont.semibold(size: 13)
        revokeButton.addTarget(self, action: #selector(handleRevokeTapped), for: .touchUpInside)

        contentView.addSubview(containerView)
        containerView.addSubview(avatarImageView)
        containerView.addSubview(nameLabel)
        containerView.addSubview(revokeButton)
    }

    private func configureLayout() {
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: Constants.containerInset),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: Constants.horizontalInset),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -Constants.horizontalInset),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -Constants.containerInset),

            avatarImageView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            avatarImageView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 14),
            avatarImageView.widthAnchor.constraint(equalToConstant: Constants.avatarSize),
            avatarImageView.heightAnchor.constraint(equalToConstant: Constants.avatarSize),

            nameLabel.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            nameLabel.leadingAnchor.constraint(equalTo: avatarImageView.trailingAnchor, constant: 18),
            nameLabel.trailingAnchor.constraint(lessThanOrEqualTo: revokeButton.leadingAnchor, constant: -12),

            revokeButton.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            revokeButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -14),
            revokeButton.widthAnchor.constraint(equalToConstant: Constants.revokeButtonWidth),
            revokeButton.heightAnchor.constraint(equalToConstant: Constants.revokeButtonHeight)
        ])
    }

    @objc private func handleRevokeTapped() {
        onRevokeTapped?()
    }
}
