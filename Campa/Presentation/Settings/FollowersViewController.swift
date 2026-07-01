import UIKit

final class FollowersViewController: BaseViewController {
    private enum Constants {
        static let horizontalInset: CGFloat = 32
        static let rowHeight: CGFloat = 78
        static let tableTopInset: CGFloat = 20
        static let titleColor = UIColor(red: 0.20, green: 0.17, blue: 0.17, alpha: 1.0)
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
        loadFollowerUsers()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        tableView.backgroundView?.frame = tableView.bounds
    }

    private func configureNavigation() {
        view.backgroundColor = Constants.backgroundColor
        changeNavbar(.backTiltle)
        setTitleAndRight(title: NSLocalizedString("Followers", comment: "Followers list title"), right: nil)
    }

    private func configureTableView() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.showsVerticalScrollIndicator = false
        tableView.rowHeight = Constants.rowHeight
        tableView.dataSource = self
        tableView.register(FollowerTableViewCell.self, forCellReuseIdentifier: FollowerTableViewCell.reuseIdentifier)

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

    private func loadFollowerUsers() {
        guard let currentUser = makeCurrentUser() else {
            users = []
            updateEmptyState()
            return
        }

        self.currentUser = currentUser
        switch userRepository.fetchFollowerUsers(for: currentUser) {
        case .success(let followerUsers):
            users = followerUsers
        case .failure:
            users = []
        }

        tableView.reloadData()
        updateEmptyState()
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

    private func follow(user: User) {
        guard let currentUser, currentUser.objectID != user.objectID else { return }

        _ = userRepository.addRelation(from: currentUser, to: user, type: .follow)
        loadFollowerUsers()
    }

    private func updateEmptyState() {
        tableView.backgroundView = users.isEmpty ? EmptyView(frame: tableView.bounds) : nil
        tableView.isScrollEnabled = !users.isEmpty
    }
}

extension FollowersViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        users.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: FollowerTableViewCell.reuseIdentifier,
            for: indexPath
        ) as? FollowerTableViewCell else {
            return UITableViewCell()
        }

        let user = users[indexPath.row]
        cell.configure(user: user, isFollowing: isFollowing(user))
        cell.onAddTapped = { [weak self] in
            self?.follow(user: user)
        }
        return cell
    }

    private func isFollowing(_ user: User) -> Bool {
        guard let currentUser,
              currentUser.objectID != user.objectID,
              case .success(true) = userRepository.hasRelation(from: currentUser, to: user, type: .follow) else {
            return false
        }
        return true
    }
}

private final class FollowerTableViewCell: UITableViewCell {
    static let reuseIdentifier = "FollowerTableViewCell"

    private enum Constants {
        static let horizontalInset: CGFloat = 20
        static let containerInset: CGFloat = 8
        static let avatarSize: CGFloat = 48
        static let addButtonWidth: CGFloat = 64
        static let addButtonHeight: CGFloat = 38
    }

    private let containerView = UIView()
    private let avatarImageView = UIImageView()
    private let nameLabel = UILabel()
    private let addButton = UIButton(type: .custom)
    var onAddTapped: (() -> Void)?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        configureViews()
        configureLayout()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }

    func configure(user: User, isFollowing: Bool) {
        nameLabel.text = user.nickname
        avatarImageView.image = makeAvatarImage(from: user.avatarLocalPath)
        addButton.isHidden = isFollowing
        onAddTapped = nil
    }

    private func makeAvatarImage(from avatarLocalPath: String?) -> UIImage? {
        UIImage.sandboxOrAssetImage(named: avatarLocalPath, documentsSubdirectory: "Avatars", fallbackName: "user_icon")
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

        addButton.translatesAutoresizingMaskIntoConstraints = false
        addButton.backgroundColor = .black
        addButton.layer.cornerRadius = Constants.addButtonHeight / 2
        addButton.setImage(UIImage(named: "add_pupor"), for: .normal)
        addButton.tintColor = UIColor(red: 0.69, green: 0.59, blue: 0.96, alpha: 1.0)
        addButton.addTarget(self, action: #selector(handleAddTapped), for: .touchUpInside)

        contentView.addSubview(containerView)
        containerView.addSubview(avatarImageView)
        containerView.addSubview(nameLabel)
        containerView.addSubview(addButton)
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
            nameLabel.trailingAnchor.constraint(lessThanOrEqualTo: addButton.leadingAnchor, constant: -12),

            addButton.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            addButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -14),
            addButton.widthAnchor.constraint(equalToConstant: Constants.addButtonWidth),
            addButton.heightAnchor.constraint(equalToConstant: Constants.addButtonHeight)
        ])
    }

    @objc private func handleAddTapped() {
        onAddTapped?()
    }
}
