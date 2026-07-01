import IQKeyboardManagerSwift
import UIKit

final class PostDetailViewController: BaseViewController {
    fileprivate enum Constants {
        static let backgroundColor = UIColor(red: 0.98, green: 0.93, blue: 0.86, alpha: 1.0)
        static let darkTextColor = UIColor(red: 0.28, green: 0.02, blue: 0.02, alpha: 1.0)
        static let mutedTextColor = UIColor(red: 0.45, green: 0.37, blue: 0.32, alpha: 1.0)
        static let burgundyColor = UIColor(red: 0.20, green: 0.02, blue: 0.02, alpha: 1.0)
        static let limeColor = UIColor(red: 0.86, green: 0.90, blue: 0.12, alpha: 1.0)
        static let purpleColor = UIColor(red: 0.70, green: 0.60, blue: 0.96, alpha: 1.0)
        static let inputHeight: CGFloat = 48
        static let inputVerticalInset: CGFloat = 8
        static let inputBottomInset: CGFloat = 34
        static let keyboardInputSpacing: CGFloat = 12
        static let maxInputLines: CGFloat = 4
    }

    private let post: Post
    private let homePost: HomePost
    private let activityRepository: ActivityRepository
    private let postRepository: PostRepository
    private let userRepository: UserRepository
    private var comments: [PostDetailComment] = []

    private let heroImageView = UIImageView()
    private let thumbnailsStackView = UIStackView()
    private let bodyLabel = UILabel()
    private let locationIconView = UIImageView()
    private let locationLabel = UILabel()
    private let commentPillLabel = PaddingLabel(contentInset: UIEdgeInsets(top: 3, left: 8, bottom: 3, right: 8))
    private let hotImageView = UIImageView()
    private let commentsTableView = UITableView(frame: .zero, style: .plain)
    private let inputContainerView = UIView()
    private let inputTextView = UITextView()
    private let inputPlaceholderLabel = UILabel()
    private let sendButton = UIButton(type: .custom)
    private var inputContainerHeightConstraint: NSLayoutConstraint?
    private var inputContainerBottomConstraint: NSLayoutConstraint?

    init(
        post: Post,
        homePost: HomePost,
        activityRepository: ActivityRepository = ActivityRepository(),
        postRepository: PostRepository = PostRepository(),
        userRepository: UserRepository = UserRepository()
    ) {
        self.post = post
        self.homePost = homePost
        self.activityRepository = activityRepository
        self.postRepository = postRepository
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
        configureHero()
        configureContent()
        configureInputBar()
        configureLayout()
        configureKeyboardHandling()
        applyPost()
        updateRightButtonVisibility()
        loadComments()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateInputTextViewHeight()
    }

    private func configureView() {
        changeNavbar(.backRightBtn)
        self.setTitleAndRight(title: nil, right: "more", rightSize: CGSizeMake(36, 36))
    }

    private func configureHero() {
        heroImageView.translatesAutoresizingMaskIntoConstraints = false
        heroImageView.contentMode = .scaleAspectFill
        heroImageView.clipsToBounds = true
        heroImageView.layer.cornerRadius = 16
        heroImageView.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]

        thumbnailsStackView.translatesAutoresizingMaskIntoConstraints = false
        thumbnailsStackView.axis = .horizontal
        thumbnailsStackView.distribution = .fillEqually
        thumbnailsStackView.spacing = 6

        view.addSubview(heroImageView)
        view.addSubview(thumbnailsStackView)
        view.bringSubviewToFront(navBar)
    }

    private func configureContent() {
        bodyLabel.translatesAutoresizingMaskIntoConstraints = false
        bodyLabel.font = AppFont.semibold(size: 12)
        bodyLabel.textColor = Constants.darkTextColor
        bodyLabel.numberOfLines = 0

        locationIconView.translatesAutoresizingMaskIntoConstraints = false
        locationIconView.image = UIImage(named: "location")
        locationIconView.contentMode = .scaleAspectFit

        locationLabel.translatesAutoresizingMaskIntoConstraints = false
        locationLabel.font = AppFont.semibold(size: 10)
        locationLabel.textColor = Constants.darkTextColor

        commentPillLabel.translatesAutoresizingMaskIntoConstraints = false
        commentPillLabel.text = NSLocalizedString("Comment", comment: "Post detail comment section")
        commentPillLabel.font = AppFont.medium(size: 10)
        commentPillLabel.textColor = Constants.darkTextColor
        commentPillLabel.layer.borderColor = Constants.darkTextColor.cgColor
        commentPillLabel.layer.borderWidth = 1
        commentPillLabel.layer.cornerRadius = 10
        commentPillLabel.clipsToBounds = true

        hotImageView.translatesAutoresizingMaskIntoConstraints = false
        hotImageView.image = UIImage(named: "hot")
        hotImageView.contentMode = .scaleAspectFit

        commentsTableView.translatesAutoresizingMaskIntoConstraints = false
        commentsTableView.backgroundColor = .clear
        commentsTableView.separatorStyle = .none
        commentsTableView.showsVerticalScrollIndicator = false
        commentsTableView.rowHeight = UITableView.automaticDimension
        commentsTableView.estimatedRowHeight = 62
        commentsTableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 16, right: 0)
        commentsTableView.dataSource = self
        commentsTableView.delegate = self
        commentsTableView.register(PostDetailCommentCell.self, forCellReuseIdentifier: PostDetailCommentCell.reuseIdentifier)

        view.addSubview(bodyLabel)
        view.addSubview(locationIconView)
        view.addSubview(locationLabel)
        view.addSubview(commentPillLabel)
        view.addSubview(hotImageView)
        view.addSubview(commentsTableView)
    }

    private func configureInputBar() {
        inputContainerView.translatesAutoresizingMaskIntoConstraints = false
        inputContainerView.backgroundColor = Constants.burgundyColor
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
        inputPlaceholderLabel.text = NSLocalizedString("Say something....", comment: "Post detail comment input placeholder")
        inputPlaceholderLabel.font = AppFont.medium(size: 12)
        inputPlaceholderLabel.textColor = UIColor(red: 0.62, green: 0.56, blue: 0.52, alpha: 1.0)

        sendButton.translatesAutoresizingMaskIntoConstraints = false
        sendButton.setImage(UIImage(named: "send"), for: .normal)
        sendButton.accessibilityIdentifier = "postDetailSendButton"
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
        inputContainerBottomConstraint = inputContainerView.bottomAnchor.constraint(
            equalTo: view.safeAreaLayoutGuide.bottomAnchor,
            constant: -Constants.inputBottomInset
        )
        inputContainerBottomConstraint?.isActive = true

        NSLayoutConstraint.activate([
            heroImageView.topAnchor.constraint(equalTo: view.topAnchor),
            heroImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            heroImageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            heroImageView.heightAnchor.constraint(equalTo: heroImageView.widthAnchor, multiplier: 0.78),

            thumbnailsStackView.leadingAnchor.constraint(equalTo: heroImageView.leadingAnchor, constant: 12),
            thumbnailsStackView.bottomAnchor.constraint(equalTo: heroImageView.bottomAnchor, constant: -12),
            thumbnailsStackView.heightAnchor.constraint(equalToConstant: 68),
            thumbnailsStackView.widthAnchor.constraint(equalToConstant: CGFloat(68 * homePost.thumbnailImages.count + (homePost.thumbnailImages.count > 1 ? (homePost.thumbnailImages.count - 1) * 6 : 6))),

            bodyLabel.topAnchor.constraint(equalTo: heroImageView.bottomAnchor, constant: 14),
            bodyLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 28),
            bodyLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -28),

            locationIconView.topAnchor.constraint(equalTo: bodyLabel.bottomAnchor, constant: 10),
            locationIconView.leadingAnchor.constraint(equalTo: bodyLabel.leadingAnchor),
            locationIconView.widthAnchor.constraint(equalToConstant: 16),
            locationIconView.heightAnchor.constraint(equalToConstant: 16),

            locationLabel.centerYAnchor.constraint(equalTo: locationIconView.centerYAnchor),
            locationLabel.leadingAnchor.constraint(equalTo: locationIconView.trailingAnchor, constant: 6),
            locationLabel.trailingAnchor.constraint(lessThanOrEqualTo: bodyLabel.trailingAnchor),

            commentPillLabel.topAnchor.constraint(equalTo: locationIconView.bottomAnchor, constant: 14),
            commentPillLabel.leadingAnchor.constraint(equalTo: bodyLabel.leadingAnchor),

            hotImageView.centerYAnchor.constraint(equalTo: commentPillLabel.centerYAnchor),
            hotImageView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -28),
            hotImageView.widthAnchor.constraint(equalToConstant: 70),
            hotImageView.heightAnchor.constraint(equalToConstant: 42),

            commentsTableView.topAnchor.constraint(equalTo: commentPillLabel.bottomAnchor, constant: 12),
            commentsTableView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            commentsTableView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            commentsTableView.bottomAnchor.constraint(equalTo: inputContainerView.topAnchor, constant: -12),

            inputContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 22),
            inputContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -22),

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

    private func configureKeyboardHandling() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleKeyboardFrameChanged(_:)),
            name: UIResponder.keyboardWillChangeFrameNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleKeyboardFrameChanged(_:)),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
    }

    private func applyPost() {
        heroImageView.image = homePost.heroImage ?? homePost.thumbnailImages.first ?? UIImage(named: "photo")
        bodyLabel.text = homePost.body
        locationLabel.text = homePost.school
        hotImageView.isHidden = !homePost.isHot

        thumbnailsStackView.arrangedSubviews.forEach { view in
            thumbnailsStackView.removeArrangedSubview(view)
            view.removeFromSuperview()
        }

        let thumbnailImages = homePost.thumbnailImages.isEmpty
            ? [homePost.heroImage].compactMap { $0 }
            : homePost.thumbnailImages

        thumbnailImages.prefix(4).enumerated().forEach { index, image in
            thumbnailsStackView.addArrangedSubview(makeThumbnailImageView(image: image, index: index))
        }
    }

    private func loadComments() {
        guard case .success(let postComments) = activityRepository.fetchComments(forPostId: post.id) else {
            comments = []
            updateComments()
            return
        }

        let blockedUserIds = blockedUserIdsForCurrentUser()
        comments = postComments
            .filter { comment in
                guard let authorId = comment.author?.id else {
                    return true
                }
                return !blockedUserIds.contains(authorId)
            }
            .map { comment in
                PostDetailComment(
                    author: comment.author,
                    authorName: comment.author?.nickname ?? NSLocalizedString("Unknown", comment: "Unknown comment author"),
                    content: comment.content,
                    avatarImage: makeAvatarImage(from: comment.author?.avatarLocalPath),
                    isCurrentUserComment: comment.author?.id == loadCurrentUser()?.id
                )
            }
        updateComments()
    }

    private func blockedUserIdsForCurrentUser() -> Set<UUID> {
        guard let currentUser = loadCurrentUser(),
              case .success(let blockedUsers) = userRepository.fetchBlockedUsers(for: currentUser) else {
            return []
        }

        return Set(blockedUsers.map(\.id))
    }

    private func updateComments() {
        let isEmpty = comments.isEmpty
        commentsTableView.backgroundView = isEmpty ? EmptyView(frame: commentsTableView.bounds) : nil
        commentsTableView.isScrollEnabled = !isEmpty
        commentsTableView.reloadData()
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

    @objc private func handleKeyboardFrameChanged(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let keyboardFrame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else {
            return
        }

        let keyboardFrameInView = view.convert(keyboardFrame, from: nil)
        let keyboardOverlap = max(0, view.bounds.maxY - keyboardFrameInView.minY - view.safeAreaInsets.bottom)
        let bottomInset = keyboardOverlap > 0
            ? keyboardOverlap + Constants.keyboardInputSpacing
            : Constants.inputBottomInset
        inputContainerBottomConstraint?.constant = -bottomInset

        let duration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval ?? 0.25
        let curveRawValue = userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as? UInt ?? 0
        let options = UIView.AnimationOptions(rawValue: curveRawValue << 16)

        UIView.animate(withDuration: duration, delay: 0, options: options) {
            self.view.layoutIfNeeded()
        }
    }

    @objc private func handleSendTapped() {
        let text = inputTextView.text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else {
            return
        }
        guard let currentUser = loadCurrentUser() else {
            AppToast.show(message: NSLocalizedString("User not found.", comment: "Missing user toast"), in: view)
            return
        }

        switch postRepository.addComment(to: post, author: currentUser, content: text, parentComment: nil) {
        case .success:
            inputTextView.text = ""
            updatePlaceholderVisibility()
            updateInputTextViewHeight()
            loadComments()
            scrollToCommentsBottom()
        case .failure:
            AppToast.show(message: NSLocalizedString("Failed to send comment.", comment: "Send comment failure toast"), in: view)
        }
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

    private func scrollToCommentsBottom() {
        guard !comments.isEmpty else {
            return
        }

        commentsTableView.scrollToRow(
            at: IndexPath(row: 0, section: 0),
            at: .top,
            animated: true
        )
    }

    private func makeThumbnailImageView(image: UIImage, index: Int) -> UIImageView {
        let imageView = UIImageView()
        imageView.image = image
        imageView.tag = index
        imageView.contentMode = .scaleAspectFill
        imageView.layer.cornerRadius = 12
        imageView.layer.borderColor = UIColor.white.withAlphaComponent(0.5).cgColor
        imageView.layer.borderWidth = 1
        imageView.clipsToBounds = true
        imageView.isUserInteractionEnabled = true
        imageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleThumbnailTapped(_:))))
        return imageView
    }

    @objc private func handleThumbnailTapped(_ sender: UITapGestureRecognizer) {
        guard let imageView = sender.view as? UIImageView,
              let image = imageView.image else {
            return
        }

        heroImageView.image = image
    }

    private func makeAvatarImage(from storedPath: String?) -> UIImage? {
        UIImage.sandboxOrAssetImage(named: storedPath, documentsSubdirectory: "Avatars", fallbackName: "muser")
    }

    private func cleanedText(_ text: String?) -> String? {
        let value = text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return value.isEmpty ? nil : value
    }

    private func updateRightButtonVisibility() {
        rightBtn.isHidden = post.author?.id == loadCurrentUser()?.id
    }

    override func rightAction() {
        let viewController = ReportAlertController()
        viewController.modalPresentationStyle = .overFullScreen
        viewController.actionHandler = { [weak self] result in
            guard let self = self else { return }
            DispatchQueue.main.async {
                if result {
                    self.blockPostAuthor()
                } else {
                    let reportViewController = ReportViewController()
                    self.navigationController?.pushViewController(reportViewController, animated: true)
                }
            }
        }
        present(viewController, animated: false)
    }

    private func blockPostAuthor() {
        guard let currentUser = loadCurrentUser() else {
            AppToast.show(message: NSLocalizedString("Failed to block user.", comment: "Block user failure toast"), in: view)
            return
        }

        guard let receiverUser = post.author else {
            AppToast.show(message: NSLocalizedString("Failed to block user.", comment: "Block user failure toast"), in: view)
            return
        }

        guard currentUser.id != receiverUser.id else {
            AppToast.show(message: NSLocalizedString("You cannot block yourself.", comment: "Block self toast"), in: view)
            return
        }

        switch userRepository.addRelation(from: currentUser, to: receiverUser, type: .block) {
        case .success:
            loadComments()
            AppToast.show(message: NSLocalizedString("User has been blocked.", comment: "Block user success toast"), in: view)
        case .failure(.duplicateRelation):
            loadComments()
            AppToast.show(message: NSLocalizedString("User has been blocked.", comment: "Block user duplicate toast"), in: view)
        case .failure:
            AppToast.show(message: NSLocalizedString("Failed to block user.", comment: "Block user failure toast"), in: view)
        }
    }
}

extension PostDetailViewController: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        updatePlaceholderVisibility()
        updateInputTextViewHeight()
    }
}

extension PostDetailViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        comments.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: PostDetailCommentCell.reuseIdentifier,
            for: indexPath
        ) as? PostDetailCommentCell else {
            return UITableViewCell()
        }

        let comment = comments[indexPath.row]
        cell.configure(comment: comment)
        cell.onAvatarTapped = { [weak self] in
            self?.showCommentAuthorProfile(comment)
        }
        cell.onMoreTapped = { [weak self] in
            self?.showCommentReportAlert(comment)
        }
        return cell
    }

    private func showCommentAuthorProfile(_ comment: PostDetailComment) {
        guard let author = comment.author else {
            return
        }

        if let currentUser = loadCurrentUser(), currentUser.id == author.id {
            switchToProfileTab()
            return
        }

        let viewController = OtherProfileViewController(userId: author.id)
        viewController.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(viewController, animated: true)
    }

    private func switchToProfileTab() {
        if let mainTabBarController = tabBarController as? MainTabBarController {
            mainTabBarController.switchToProfileTab()
            return
        }

        if let mainTabBarController = view.window?.rootViewController as? MainTabBarController {
            mainTabBarController.switchToProfileTab()
            return
        }

        let mainTabBarController = MainTabBarController()
        view.window?.rootViewController = mainTabBarController
        mainTabBarController.switchToProfileTab()
    }

    private func showCommentReportAlert(_ comment: PostDetailComment) {
        let viewController = ReportAlertController()
        viewController.modalPresentationStyle = .overFullScreen
        viewController.actionHandler = { [weak self] result in
            guard let self = self else { return }
            DispatchQueue.main.async {
                if result {
                    self.blockCommentAuthor(comment)
                } else {
                    let reportViewController = ReportViewController()
                    self.navigationController?.pushViewController(reportViewController, animated: true)
                }
            }
        }
        present(viewController, animated: false)
    }

    private func blockCommentAuthor(_ comment: PostDetailComment) {
        guard let currentUser = loadCurrentUser() else {
            AppToast.show(message: NSLocalizedString("Failed to block user.", comment: "Block user failure toast"), in: view)
            return
        }

        guard let receiverUser = comment.author else {
            AppToast.show(message: NSLocalizedString("Failed to block user.", comment: "Block user failure toast"), in: view)
            return
        }

        guard currentUser.id != receiverUser.id else {
            AppToast.show(message: NSLocalizedString("You cannot block yourself.", comment: "Block self toast"), in: view)
            return
        }

        switch userRepository.addRelation(from: currentUser, to: receiverUser, type: .block) {
        case .success:
            loadComments()
            AppToast.show(message: NSLocalizedString("User has been blocked.", comment: "Block user success toast"), in: view)
        case .failure(.duplicateRelation):
            loadComments()
            AppToast.show(message: NSLocalizedString("User has been blocked.", comment: "Block user duplicate toast"), in: view)
        case .failure:
            AppToast.show(message: NSLocalizedString("Failed to block user.", comment: "Block user failure toast"), in: view)
        }
    }
}

private struct PostDetailComment {
    let author: User?
    let authorName: String
    let content: String
    let avatarImage: UIImage?
    let isCurrentUserComment: Bool
}

private final class PostDetailCommentCell: UITableViewCell {
    static let reuseIdentifier = "PostDetailCommentCell"

    private let commentView = PostDetailCommentView()
    var onAvatarTapped: (() -> Void)?
    var onMoreTapped: (() -> Void)?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        configure()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        onAvatarTapped = nil
        onMoreTapped = nil
    }

    func configure(comment: PostDetailComment) {
        commentView.configure(comment: comment)
        commentView.onAvatarTapped = { [weak self] in
            self?.onAvatarTapped?()
        }
        commentView.onMoreTapped = { [weak self] in
            self?.onMoreTapped?()
        }
    }

    private func configure() {
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        selectionStyle = .none

        commentView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(commentView)

        NSLayoutConstraint.activate([
            commentView.topAnchor.constraint(equalTo: contentView.topAnchor),
            commentView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            commentView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            commentView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8)
        ])
    }
}

private final class PostDetailCommentView: UIView {
    private let avatarImageView = UIImageView()
    private let nameLabel = UILabel()
    private let contentLabel = UILabel()
    private let moreButton = UIButton(type: .custom)
    var onAvatarTapped: (() -> Void)?
    var onMoreTapped: (() -> Void)?

    init(comment: PostDetailComment? = nil) {
        super.init(frame: .zero)

        configureView()
        configureLayout()
        if let comment {
            configure(comment: comment)
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }

    private func configureView() {
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = .white
        layer.cornerRadius = 16
        clipsToBounds = true

        avatarImageView.translatesAutoresizingMaskIntoConstraints = false
        avatarImageView.contentMode = .scaleAspectFill
        avatarImageView.layer.cornerRadius = 17
        avatarImageView.clipsToBounds = true
        avatarImageView.isUserInteractionEnabled = true
        avatarImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleAvatarTapped)))

        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.font = AppFont.semibold(size: 12)
        nameLabel.textColor = PostDetailViewController.Constants.darkTextColor

        contentLabel.translatesAutoresizingMaskIntoConstraints = false
        contentLabel.font = AppFont.medium(size: 10)
        contentLabel.textColor = PostDetailViewController.Constants.mutedTextColor
        contentLabel.numberOfLines = 0

        moreButton.translatesAutoresizingMaskIntoConstraints = false
        moreButton.setImage(UIImage(named: "more_gray") ?? UIImage(systemName: "ellipsis"), for: .normal)
        moreButton.addTarget(self, action: #selector(handleMoreTapped), for: .touchUpInside)

        addSubview(avatarImageView)
        addSubview(nameLabel)
        addSubview(contentLabel)
        addSubview(moreButton)
    }

    private func configureLayout() {
        NSLayoutConstraint.activate([
            heightAnchor.constraint(greaterThanOrEqualToConstant: 54),

            avatarImageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            avatarImageView.centerYAnchor.constraint(equalTo: centerYAnchor),
            avatarImageView.widthAnchor.constraint(equalToConstant: 34),
            avatarImageView.heightAnchor.constraint(equalToConstant: 34),

            moreButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10),
            moreButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            moreButton.widthAnchor.constraint(equalToConstant: 30),
            moreButton.heightAnchor.constraint(equalToConstant: 30),

            nameLabel.topAnchor.constraint(equalTo: topAnchor, constant: 11),
            nameLabel.leadingAnchor.constraint(equalTo: avatarImageView.trailingAnchor, constant: 10),
            nameLabel.trailingAnchor.constraint(lessThanOrEqualTo: moreButton.leadingAnchor, constant: -8),

            contentLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 3),
            contentLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            contentLabel.trailingAnchor.constraint(equalTo: moreButton.leadingAnchor, constant: -8),
            contentLabel.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor, constant: -9)
        ])
    }

    func configure(comment: PostDetailComment) {
        avatarImageView.image = comment.avatarImage ?? UIImage(named: "muser")
        nameLabel.text = comment.authorName
        contentLabel.text = comment.content
        moreButton.isHidden = comment.isCurrentUserComment
    }

    @objc private func handleAvatarTapped() {
        onAvatarTapped?()
    }

    @objc private func handleMoreTapped() {
        onMoreTapped?()
    }
}

private final class PaddingLabel: UILabel {
    private let contentInset: UIEdgeInsets

    init(contentInset: UIEdgeInsets) {
        self.contentInset = contentInset
        super.init(frame: .zero)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }

    override var intrinsicContentSize: CGSize {
        let size = super.intrinsicContentSize
        return CGSize(
            width: size.width + contentInset.left + contentInset.right,
            height: size.height + contentInset.top + contentInset.bottom
        )
    }

    override func drawText(in rect: CGRect) {
        super.drawText(in: rect.inset(by: contentInset))
    }
}
