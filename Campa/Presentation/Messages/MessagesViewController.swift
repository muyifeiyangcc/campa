import IQKeyboardManagerSwift
import UIKit

final class MessagesViewController: BaseViewController {
    fileprivate enum Constants {
        static let horizontalInset: CGFloat = 22
        static let inputHeight: CGFloat = 48
        static let inputVerticalInset: CGFloat = 8
        static let maxInputLines: CGFloat = 4
        static let inputBottomInset: CGFloat = 34
        static let estimatedRowHeight: CGFloat = 115
        static let rowSpacing: CGFloat = 18
    }

    private let viewModel: MessagesViewModel
    private let chatRepository: ChatRepository
    private let userRepository: UserRepository
    private let receiverUserId: UUID?
    private var conversation: ChatConversation?
    private var messages: [MessageBubble] = []
    private let tableView = UITableView(frame: .zero, style: .plain)
    private let inputContainerView = UIView()
    private let inputTextView = UITextView()
    private let inputPlaceholderLabel = UILabel()
    private let sendButton = UIButton(type: .custom)
    private var inputContainerHeightConstraint: NSLayoutConstraint?

    init(
        conversation: ChatConversation? = nil,
        receiverUserId: UUID? = nil,
        viewModel: MessagesViewModel = MessagesViewModel(),
        chatRepository: ChatRepository = ChatRepository(),
        userRepository: UserRepository = UserRepository()
    ) {
        self.conversation = conversation
        self.viewModel = viewModel
        self.chatRepository = chatRepository
        self.userRepository = userRepository
        self.receiverUserId = receiverUserId ?? Self.makeReceiverUserId(from: conversation, userRepository: userRepository)
        super.init(nibName: nil, bundle: nil)
    }

    private static func makeReceiverUserId(from conversation: ChatConversation?, userRepository: UserRepository) -> UUID? {
        guard let conversation else {
            return nil
        }

        let users = conversation.participants?.compactMap(\.user) ?? []
        if let userIdString = UserDefaults.standard.string(forKey: CurrentUserIdKey),
           let currentUserId = UUID(uuidString: userIdString) {
            return users.first { $0.id != currentUserId }?.id
        }

        if case .success(let currentUser) = userRepository.fetchCurrentUser() {
            return users.first { $0.id != currentUser.id }?.id
        }

        return users.first?.id
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        resolveConversationIfNeeded()
        configureView()
        configureMessages()
        configureInputBar()
        configureLayout()
        loadMessages()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        loadMessages()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateInputTextViewHeight()
    }

    private func configureView() {
        self.changeNavbar(.all)
        self.setTitleAndRight(title: makeTitleText(), right: "more", rightSize: CGSize(width: 36, height: 36))
    }

    override func rightAction() {
        let vc = ReportAlertController()
        vc.actionHandler = { [weak self] result in
            guard let self = self else { return }
            DispatchQueue.main.async {
                if result {
                    self.blockReceiverUser()
                } else {
                    let reportVC = ReportViewController()
                    self.navigationController?.pushViewController(reportVC, animated: true)
                }
            }
        }
        vc.modalPresentationStyle = .overFullScreen
        self.present(vc, animated: false)
    }

    private func blockReceiverUser() {
        guard  let currentUser = loadCurrentUser() else {
            AppToast.show(message: NSLocalizedString("Failed to block user.", comment: "Block user failure toast"), in: view)
             return
        }
        guard let uid = self.receiverUserId,
              case .success(let receiverUser) = userRepository.fetchUser(id: uid) else {
             AppToast.show(message: NSLocalizedString("Failed to block user.", comment: "Block user failure toast"), in: view)
            return
        }

        switch userRepository.addRelation(from: currentUser, to: receiverUser, type: .block) {
        case .success:
            AppToast.show(message: NSLocalizedString("User has been blocked.", comment: "Block user success toast"), in: view)
        case .failure(.duplicateRelation):
            AppToast.show(message: NSLocalizedString("User has been blocked.", comment: "Block user duplicate toast"), in: view)
        case .failure:
            AppToast.show(message: NSLocalizedString("Failed to block user.", comment: "Block user failure toast"), in: view)
        }
    }
    
    private func configureMessages() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.showsVerticalScrollIndicator = false
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = Constants.estimatedRowHeight
        tableView.dataSource = self
        tableView.register(MessageBubbleTableViewCell.self, forCellReuseIdentifier: MessageBubbleTableViewCell.reuseIdentifier)

        view.addSubview(tableView)
    }

    private func configureInputBar() {
        inputContainerView.translatesAutoresizingMaskIntoConstraints = false
        inputContainerView.backgroundColor = UIColor(red: 52/255.0, green: 4/255, blue: 4/255.0, alpha: 1.0)
        inputContainerView.layer.cornerRadius = 8

        inputTextView.translatesAutoresizingMaskIntoConstraints = false
        inputTextView.backgroundColor = .clear
        inputTextView.font = AppFont.medium(size: 14)
        inputTextView.textColor = .white
        inputTextView.textContainerInset = UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 0)
        inputTextView.textContainer.lineFragmentPadding = 0
        inputTextView.showsVerticalScrollIndicator = false
        inputTextView.isScrollEnabled = false
        inputTextView.delegate = self
        inputTextView.iq.enableMode = .disabled

        inputPlaceholderLabel.translatesAutoresizingMaskIntoConstraints = false
        inputPlaceholderLabel.text = viewModel.inputPlaceholder
        inputPlaceholderLabel.font = AppFont.medium(size: 12)
        inputPlaceholderLabel.textColor = UIColor(red: 0.62, green: 0.56, blue: 0.52, alpha: 1.0)

        sendButton.translatesAutoresizingMaskIntoConstraints = false
        sendButton.setImage(UIImage(named: "send"), for: .normal)
        sendButton.accessibilityIdentifier = "messagesSendButton"
        sendButton.addTarget(self, action: #selector(handleSendTapped), for: .touchUpInside)

        inputContainerView.addSubview(inputTextView)
        inputTextView.addSubview(inputPlaceholderLabel)
        inputContainerView.addSubview(sendButton)
        view.addSubview(inputContainerView)
        updatePlaceholderVisibility()
    }

    private func configureLayout() {
        inputContainerHeightConstraint = inputContainerView.heightAnchor.constraint(equalToConstant: Constants.inputHeight)
        inputContainerHeightConstraint?.isActive = true

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: navBar.bottomAnchor, constant: 24),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: inputContainerView.topAnchor, constant: -18),

            inputContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: Constants.horizontalInset),
            inputContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -Constants.horizontalInset),
            inputContainerView.bottomAnchor.constraint(equalTo: view.keyboardLayoutGuide.topAnchor, constant: -Constants.inputBottomInset),

            inputTextView.topAnchor.constraint(equalTo: inputContainerView.topAnchor, constant: Constants.inputVerticalInset),
            inputTextView.leadingAnchor.constraint(equalTo: inputContainerView.leadingAnchor, constant: 18),
            inputTextView.trailingAnchor.constraint(equalTo: sendButton.leadingAnchor, constant: -12),
            inputTextView.bottomAnchor.constraint(equalTo: inputContainerView.bottomAnchor, constant: -Constants.inputVerticalInset),

            inputPlaceholderLabel.topAnchor.constraint(equalTo: inputTextView.topAnchor, constant: 8),
            inputPlaceholderLabel.leadingAnchor.constraint(equalTo: inputTextView.leadingAnchor),
            inputPlaceholderLabel.trailingAnchor.constraint(lessThanOrEqualTo: inputTextView.trailingAnchor),

            sendButton.trailingAnchor.constraint(equalTo: inputContainerView.trailingAnchor, constant: -16),
            sendButton.centerYAnchor.constraint(equalTo: inputContainerView.centerYAnchor),
            sendButton.widthAnchor.constraint(equalToConstant: 36),
            sendButton.heightAnchor.constraint(equalToConstant: 36)
        ])
    }

    private func updatePlaceholderVisibility() {
        inputPlaceholderLabel.isHidden = !inputTextView.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func updateInputTextViewHeight() {
        let textWidth = inputTextView.bounds.width
        guard textWidth > 0 else {
            return
        }

        let fittingHeight = inputTextView.sizeThatFits(
            CGSize(width: textWidth, height: CGFloat.greatestFiniteMagnitude)
        ).height
        let lineHeight = inputTextView.font?.lineHeight ?? AppFont.medium(size: 12).lineHeight
        let maxTextHeight = lineHeight * Constants.maxInputLines
            + inputTextView.textContainerInset.top
            + inputTextView.textContainerInset.bottom
        let textHeight = min(fittingHeight, maxTextHeight)
        let containerHeight = max(Constants.inputHeight, textHeight + Constants.inputVerticalInset * 2)

        inputTextView.isScrollEnabled = fittingHeight > maxTextHeight
        guard abs((inputContainerHeightConstraint?.constant ?? 0) - containerHeight) > 0.5 else {
            return
        }

        inputContainerHeightConstraint?.constant = containerHeight
    }

    @objc private func handleSendTapped() {
        let text = inputTextView.text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else {
            return
        }
        guard let conversation else {
            AppToast.show(message: NSLocalizedString("Conversation not found.", comment: "Missing conversation toast"), in: view)
            return
        }
        guard let currentUser = loadCurrentUser() else {
            AppToast.show(message: NSLocalizedString("User not found.", comment: "Missing user toast"), in: view)
            return
        }

        switch chatRepository.insertTextMessage(text, from: currentUser, in: conversation) {
        case .success:
            inputTextView.text = ""
            updatePlaceholderVisibility()
            updateInputTextViewHeight()
            loadMessages()
        case .failure:
            AppToast.show(message: NSLocalizedString("Failed to send message.", comment: "Send message failure toast"), in: view)
        }
    }

    private func loadMessages() {
        guard let conversation,
              let currentUser = loadCurrentUser(),
              case .success(let chatMessages) = chatRepository.fetchMessages(in: conversation) else {
            messages = []
            tableView.reloadData()
            return
        }

        let receiver = makeReceiverUser(from: conversation, currentUser: currentUser)
        let currentUserAvatar = makeAvatarImage(from: currentUser.avatarLocalPath)
        let receiverAvatar = makeAvatarImage(from: receiver?.avatarLocalPath)
        messages = chatMessages.map { message in
            let isOutgoing = message.sender?.id == currentUser.id
            return MessageBubble(
                text: message.content ?? "",
                isOutgoing: isOutgoing,
                avatarImage: isOutgoing ? currentUserAvatar : receiverAvatar
            )
        }
        tableView.reloadData()
        scrollToBottom(animated: false)
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

    private func makeReceiverUser(from conversation: ChatConversation, currentUser: User) -> User? {
        conversation.participants?
            .compactMap(\.user)
            .first { $0.id != currentUser.id }
    }

    private func makeAvatarImage(from storedPath: String?) -> UIImage? {
        UIImage.sandboxOrAssetImage(named: storedPath, documentsSubdirectory: "Avatars", fallbackName: "user_icon")
    }

    private func resolveConversationIfNeeded() {
        guard conversation == nil,
              let receiverUserId,
              let currentUser = loadCurrentUser(),
              case .success(let receiver) = userRepository.fetchUser(id: receiverUserId) else {
            return
        }

        switch chatRepository.fetchPrivateConversation(between: currentUser, and: receiver) {
        case .success(let existingConversation):
            if let existingConversation {
                conversation = existingConversation
                return
            }
            if case .success(let newConversation) = chatRepository.createConversation(
                type: .private,
                title: nil,
                participants: [currentUser, receiver]
            ) {
                conversation = newConversation
            }
        case .failure:
            return
        }
    }

    private func makeTitleText() -> String {
        guard let conversation else {
            if let receiverUserId,
               case .success(let receiver) = userRepository.fetchUser(id: receiverUserId) {
                return receiver.nickname
            }
            return viewModel.title
        }

        if let title = cleanedText(conversation.title) {
            return title
        }

        let currentUserId = UserDefaults.standard.string(forKey: CurrentUserIdKey).flatMap { UUID(uuidString: $0) }
        let users = conversation.participants?.compactMap(\.user) ?? []
        if let currentUserId,
           let otherUser = users.first(where: { $0.id != currentUserId }) {
            return otherUser.nickname
        }
        return users.first?.nickname ?? viewModel.title
    }

    private func scrollToBottom(animated: Bool) {
        guard !messages.isEmpty else {
            return
        }

        let indexPath = IndexPath(row: messages.count - 1, section: 0)
        tableView.scrollToRow(at: indexPath, at: .bottom, animated: animated)
    }

    private func cleanedText(_ text: String?) -> String? {
        let value = text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return value.isEmpty ? nil : value
    }
}

extension MessagesViewController: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        updatePlaceholderVisibility()
        updateInputTextViewHeight()
    }
}

extension MessagesViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        messages.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: MessageBubbleTableViewCell.reuseIdentifier,
            for: indexPath
        ) as? MessageBubbleTableViewCell else {
            return UITableViewCell()
        }

        cell.configure(message: messages[indexPath.row])
        return cell
    }
}

private final class MessageBubbleTableViewCell: UITableViewCell {
    static let reuseIdentifier = "MessageBubbleTableViewCell"

    private let bubbleView = MessageBubbleView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        configure()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }

    func configure(message: MessageBubble) {
        bubbleView.configure(message: message)
    }

    private func configure() {
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        selectionStyle = .none

        bubbleView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(bubbleView)

        NSLayoutConstraint.activate([
            bubbleView.topAnchor.constraint(equalTo: contentView.topAnchor),
            bubbleView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: MessagesViewController.Constants.horizontalInset),
            bubbleView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -MessagesViewController.Constants.horizontalInset),
            bubbleView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -MessagesViewController.Constants.rowSpacing)
        ])
    }
}

private final class MessageBubbleView: UIView {
    private let avatarImageView = UIImageView()
    private let bubbleLabel = UILabel()
    private let bubbleContainerView = UIView()

    init(message: MessageBubble? = nil) {
        super.init(frame: .zero)

        configureView()
        configureLayout()

        if let message {
            configure(message: message)
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }

    func configure(message: MessageBubble) {
        avatarImageView.image = message.avatarImage ?? UIImage(named: "user_icon")
        bubbleLabel.text = message.text
        bubbleContainerView.backgroundColor = message.isOutgoing
            ? UIColor(red: 0.87, green: 0.92, blue: 0.09, alpha: 1.0)
            : UIColor(red: 0.70, green: 0.60, blue: 0.96, alpha: 1.0)
        bubbleLabel.textColor = message.isOutgoing
            ? UIColor(red: 0.28, green: 0.20, blue: 0.16, alpha: 1.0)
            : .white
        outgoingConstraints.forEach { $0.isActive = message.isOutgoing }
        incomingConstraints.forEach { $0.isActive = !message.isOutgoing }
    }

    private var incomingConstraints: [NSLayoutConstraint] = []
    private var outgoingConstraints: [NSLayoutConstraint] = []

    private func configureView() {
        translatesAutoresizingMaskIntoConstraints = false

        avatarImageView.translatesAutoresizingMaskIntoConstraints = false
        avatarImageView.image = UIImage(named: "photo")
        avatarImageView.contentMode = .scaleAspectFill
        avatarImageView.layer.cornerRadius = 18
        avatarImageView.clipsToBounds = true

        bubbleContainerView.translatesAutoresizingMaskIntoConstraints = false
        bubbleContainerView.layer.cornerRadius = 16

        bubbleLabel.translatesAutoresizingMaskIntoConstraints = false
        bubbleLabel.font = AppFont.medium(size: 12)
        bubbleLabel.numberOfLines = 0

        addSubview(avatarImageView)
        addSubview(bubbleContainerView)
        bubbleContainerView.addSubview(bubbleLabel)
    }

    private func configureLayout() {
        NSLayoutConstraint.activate([
            heightAnchor.constraint(greaterThanOrEqualToConstant: 97),

            avatarImageView.widthAnchor.constraint(equalToConstant: 36),
            avatarImageView.heightAnchor.constraint(equalToConstant: 36),
            avatarImageView.topAnchor.constraint(equalTo: topAnchor),

            bubbleContainerView.topAnchor.constraint(equalTo: avatarImageView.bottomAnchor, constant: 7),
            bubbleContainerView.bottomAnchor.constraint(equalTo: bottomAnchor),
            bubbleContainerView.widthAnchor.constraint(lessThanOrEqualTo: widthAnchor, multiplier: 0.72),

            bubbleLabel.topAnchor.constraint(equalTo: bubbleContainerView.topAnchor, constant: 12),
            bubbleLabel.leadingAnchor.constraint(equalTo: bubbleContainerView.leadingAnchor, constant: 14),
            bubbleLabel.trailingAnchor.constraint(equalTo: bubbleContainerView.trailingAnchor, constant: -14),
            bubbleLabel.bottomAnchor.constraint(equalTo: bubbleContainerView.bottomAnchor, constant: -12)
        ])

        incomingConstraints = [
            avatarImageView.leadingAnchor.constraint(equalTo: leadingAnchor),
            bubbleContainerView.leadingAnchor.constraint(equalTo: avatarImageView.leadingAnchor)
        ]
        outgoingConstraints = [
            avatarImageView.trailingAnchor.constraint(equalTo: trailingAnchor),
            bubbleContainerView.trailingAnchor.constraint(equalTo: avatarImageView.trailingAnchor)
        ]
    }
}
