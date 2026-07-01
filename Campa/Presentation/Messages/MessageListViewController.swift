import UIKit

final class MessageListViewController: BaseViewController {
    fileprivate enum Constants {
        static let horizontalInset: CGFloat = 20
        static let estimatedRowHeight: CGFloat = 75
        static let rowSpacing: CGFloat = 13
        static let cardCornerRadius: CGFloat = 16
    }

    private let viewModel: MessageListViewModel
    private let chatRepository: ChatRepository
    private let userRepository: UserRepository
    private var conversations: [ChatConversation] = []
    private var messages: [MessageListItem] = []
    private let tableView = UITableView(frame: .zero, style: .plain)
    private let emptyView = EmptyView()
    private let starContainerView = UIImageView()
    private var hasLoadedConversations = false

    init(
        viewModel: MessageListViewModel = MessageListViewModel(),
        chatRepository: ChatRepository = ChatRepository(),
        userRepository: UserRepository = UserRepository()
    ) {
        self.viewModel = viewModel
        self.chatRepository = chatRepository
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
        configureNotifications()
        configureMessages()
        configureLayout()
        loadConversations()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        loadConversations()
    }

    private func configureView() {
        self.changeNavbar(.title)
        self.setTitleAndRight(title: viewModel.title, right: nil)
        starContainerView.translatesAutoresizingMaskIntoConstraints = false
        starContainerView.backgroundColor = .clear
        starContainerView.layer.borderColor = UIColor(red: 0.45, green: 0.36, blue: 0.30, alpha: 0.45).cgColor
        starContainerView.image = UIImage(named: "star")
        starContainerView.contentMode = .scaleAspectFill
        self.navBar.addSubview(starContainerView)
        self.starContainerView.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.right.equalTo(-20)
            make.size.equalTo(CGSize(width: 88, height: 30))
        }
    }

    private func configureMessages() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.showsVerticalScrollIndicator = false
        tableView.alwaysBounceVertical = true
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = Constants.estimatedRowHeight
        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 24, right: 0)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(MessageListTableViewCell.self, forCellReuseIdentifier: MessageListTableViewCell.reuseIdentifier)

        view.addSubview(tableView)
        emptyView.translatesAutoresizingMaskIntoConstraints = false
        emptyView.isHidden = true
        view.addSubview(emptyView)
    }

    private func configureNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleUserRelationDidChange),
            name: .userFollowRelationDidChange,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleUserRelationDidChange),
            name: .userBlockRelationDidChange,
            object: nil
        )
    }

    private func configureLayout() {
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: navBar.bottomAnchor, constant: 27),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])

        NSLayoutConstraint.activate([
            emptyView.topAnchor.constraint(equalTo: navBar.bottomAnchor, constant: 27),
            emptyView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: Constants.horizontalInset),
            emptyView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -Constants.horizontalInset),
            emptyView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
    }

    private func loadConversations() {
        guard let currentUser = loadCurrentUser(),
              case .success(let conversations) = chatRepository.fetchConversationsWithMessages(for: currentUser) else {
            self.conversations = []
            messages = []
            tableView.reloadData()
            updateEmptyState()
            return
        }

        let mutualFollowConversations = conversations.filter { conversation in
            guard let displayUser = makeDisplayUser(from: conversation, currentUserId: currentUser.id) else {
                return false
            }
            return isMutualFollow(between: currentUser, and: displayUser)
        }

        let updateList = { [weak self] in
            guard let self else { return }
            self.conversations = mutualFollowConversations
            self.messages = mutualFollowConversations.map(self.makeMessageItem(from:))
            self.tableView.reloadData()
            self.updateEmptyState()
        }

        guard !hasLoadedConversations else {
            updateList()
            return
        }

        hasLoadedConversations = true
        AppLoading.show(in: view) {
            updateList()
        }
    }

    @objc private func handleUserRelationDidChange() {
        loadConversations()
    }

    private func loadCurrentUser() -> User? {
        if let userIdString = UserDefaults.standard.string(forKey: CurrentUserIdKey),
           let userId = UUID(uuidString: userIdString),
           case .success(let user) = userRepository.fetchUser(id: userId) {
            return user
        }

        guard case .success(let user) = userRepository.fetchCurrentUser() else {
            return nil
        }
        return user
    }

    private func updateEmptyState() {
        let isEmpty = messages.isEmpty
        tableView.isHidden = isEmpty
        emptyView.isHidden = !isEmpty
    }

    private func makeMessageItem(from conversation: ChatConversation) -> MessageListItem {
        let displayUser = makeDisplayUser(from: conversation)
        let sentDate = conversation.lastMessageAt ?? conversation.updatedAt
        return MessageListItem(
            name: cleanedText(conversation.title) ?? cleanedText(displayUser?.nickname) ?? NSLocalizedString("Unknown", comment: "Unknown message sender"),
            preview: cleanedText(conversation.lastMessageText) ?? "",
            time: makeTimeText(from: sentDate),
            unreadCount: conversation.unreadCount > 0 ? Int(conversation.unreadCount) : nil,
            avatarImage: makeAvatarImage(from: displayUser?.avatarLocalPath)
        )
    }

    private func makeDisplayUser(from conversation: ChatConversation) -> User? {
        return makeDisplayUser(from: conversation, currentUserId: currentUserId())
    }

    private func makeDisplayUser(from conversation: ChatConversation, currentUserId: UUID?) -> User? {
        let users = conversation.participants?
            .compactMap(\.user)
            .sorted { $0.nickname < $1.nickname } ?? []

        if let currentUserId,
           let otherUser = users.first(where: { $0.id != currentUserId }) {
            return otherUser
        }
        return users.first
    }

    private func isMutualFollow(between currentUser: User, and displayUser: User) -> Bool {
        guard currentUser.id != displayUser.id,
              case .success(true) = userRepository.hasRelation(from: currentUser, to: displayUser, type: .follow),
              case .success(true) = userRepository.hasRelation(from: displayUser, to: currentUser, type: .follow) else {
            return false
        }
        return true
    }

    private func currentUserId() -> UUID? {
        guard let userIdString = UserDefaults.standard.string(forKey: CurrentUserIdKey) else {
            return nil
        }
        return UUID(uuidString: userIdString)
    }

    private func makeTimeText(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = .current
        formatter.dateFormat = Calendar.current.isDateInToday(date) ? "h:mm a" : "MMM d"
        return formatter.string(from: date)
    }

    private func makeAvatarImage(from storedPath: String?) -> UIImage? {
        UIImage.sandboxOrAssetImage(named: storedPath, documentsSubdirectory: "Avatars", fallbackName: "user_icon")
    }

    private func cleanedText(_ text: String?) -> String? {
        let value = text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return value.isEmpty ? nil : value
    }
}

extension MessageListViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        messages.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: MessageListTableViewCell.reuseIdentifier,
            for: indexPath
        ) as? MessageListTableViewCell else {
            return UITableViewCell()
        }

        cell.configure(item: messages[indexPath.row])
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard conversations.indices.contains(indexPath.row) else {
            return
        }

        let vc = MessagesViewController(conversation: conversations[indexPath.row])
        vc.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(vc, animated: true)
    }
}

private final class MessageListTableViewCell: UITableViewCell {
    static let reuseIdentifier = "MessageListTableViewCell"

    private let cardView = MessageListCardView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        configure()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }

    func configure(item: MessageListItem) {
        cardView.configure(item: item)
    }

    private func configure() {
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        selectionStyle = .none

        cardView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(cardView)

        NSLayoutConstraint.activate([
            cardView.topAnchor.constraint(equalTo: contentView.topAnchor),
            cardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: MessageListViewController.Constants.horizontalInset),
            cardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -17),
            cardView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -MessageListViewController.Constants.rowSpacing)
        ])
    }
}

private final class MessageListCardView: UIView {
    private enum Constants {
        static let avatarSize: CGFloat = 39
        static let unreadSize: CGFloat = 14
    }

    private let avatarImageView = UIImageView()
    private let nameLabel = UILabel()
    private let previewLabel = UILabel()
    private let timeLabel = UILabel()

    init(item: MessageListItem? = nil) {
        super.init(frame: .zero)

        configureView()
        configureLayout()

        if let item {
            configure(item: item)
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }

    func configure(item: MessageListItem) {
        nameLabel.text = item.name
        previewLabel.text = item.preview
        timeLabel.text = item.time
        avatarImageView.image = item.avatarImage ?? UIImage(named: "user_icon")
    }

    private func configureView() {
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = UIColor(red: 0.86, green: 0.91, blue: 0.10, alpha: 1.0)
        layer.cornerRadius = MessageListViewController.Constants.cardCornerRadius
        clipsToBounds = true
        accessibilityIdentifier = "messageListCardView"

        avatarImageView.translatesAutoresizingMaskIntoConstraints = false
        avatarImageView.image = UIImage(named: "user_icon")
        avatarImageView.contentMode = .scaleAspectFill
        avatarImageView.layer.cornerRadius = Constants.avatarSize / 2
        avatarImageView.clipsToBounds = true

        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.font = AppFont.semibold(size: 12)
        nameLabel.textColor = UIColor(red: 0.18, green: 0.10, blue: 0.08, alpha: 1.0)
        nameLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        previewLabel.translatesAutoresizingMaskIntoConstraints = false
        previewLabel.font = AppFont.medium(size: 11)
        previewLabel.textColor = UIColor(red: 0.18, green: 0.10, blue: 0.08, alpha: 1.0)
        previewLabel.numberOfLines = 0
        previewLabel.adjustsFontSizeToFitWidth = true
        previewLabel.minimumScaleFactor = 0.85

        timeLabel.translatesAutoresizingMaskIntoConstraints = false
        timeLabel.font = AppFont.medium(size: 8)
        timeLabel.textColor = UIColor(red: 0.40, green: 0.34, blue: 0.26, alpha: 1.0)
        timeLabel.textAlignment = .right
        timeLabel.setContentCompressionResistancePriority(.required, for: .horizontal)

        addSubview(avatarImageView)
        addSubview(nameLabel)
        addSubview(previewLabel)
        addSubview(timeLabel)
    }

    private func configureLayout() {
        NSLayoutConstraint.activate([
            avatarImageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 11),
            avatarImageView.topAnchor.constraint(equalTo: topAnchor, constant: 11),
            avatarImageView.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor, constant: -12),
            avatarImageView.widthAnchor.constraint(equalToConstant: Constants.avatarSize),
            avatarImageView.heightAnchor.constraint(equalToConstant: Constants.avatarSize),

            nameLabel.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            nameLabel.leadingAnchor.constraint(equalTo: avatarImageView.trailingAnchor, constant: 17),
            nameLabel.trailingAnchor.constraint(lessThanOrEqualTo: timeLabel.leadingAnchor, constant: -8),

            previewLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 5),
            previewLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            previewLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            previewLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -14),

            timeLabel.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            timeLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -14)
        ])
    }
}
