import UIKit

final class HomeViewController: BaseViewController {
    fileprivate enum Constants {
        static let horizontalInset: CGFloat = 20
        static let backgroundColor = UIColor(red: 0.98, green: 0.93, blue: 0.86, alpha: 1.0)
        static let darkTextColor = UIColor(red: 0.28, green: 0.02, blue: 0.02, alpha: 1.0)
        static let mutedTextColor = UIColor(red: 0.45, green: 0.37, blue: 0.32, alpha: 1.0)
        static let purpleColor = UIColor(red: 0.72, green: 0.62, blue: 0.97, alpha: 1.0)
        static let limeColor = UIColor(red: 0.86, green: 0.90, blue: 0.12, alpha: 1.0)
        static let hotLikeThreshold: Int32 = 300
    }

    private let viewModel: HomeViewModel
    private let greetingLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let segmentStackView = UIStackView()
    private let pageContainerView = UIView()
    private let pageViewController: UIPageViewController
    private let userRepository: UserRepository
    private let postRepository: PostRepository

    private var segmentButtons: [UIButton] = []
    private var pageControllers: [HomePostsPageViewController] = []
    private var selectedIndex = 0

    init(
        viewModel: HomeViewModel = HomeViewModel(),
        userRepository: UserRepository = UserRepository(),
        postRepository: PostRepository = PostRepository()
    ) {
        self.viewModel = viewModel
        self.userRepository = userRepository
        self.postRepository = postRepository
        self.pageViewController = UIPageViewController(
            transitionStyle: .scroll,
            navigationOrientation: .horizontal,
            options: nil
        )
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        configureBase()
        configureNotifications()
        configureHeader()
        configureSegment()
        configurePages()
        configureLayout()
        loadPosts()
    }

    private func configureBase() {
        view.backgroundColor = Constants.backgroundColor
        navBar.backgroundColor = .clear
    }

    private func configureNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handlePostDidPublish),
            name: .postDidPublish,
            object: nil
        )
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

    private func configureHeader() {
        greetingLabel.translatesAutoresizingMaskIntoConstraints = false
        greetingLabel.text = viewModel.greetingTitle
        greetingLabel.font = AppFont.bold(size: 18)
        greetingLabel.textColor = Constants.darkTextColor

        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.text = viewModel.subtitle
        subtitleLabel.font = AppFont.medium(size: 12)
        subtitleLabel.textColor = Constants.mutedTextColor

        view.addSubview(greetingLabel)
        view.addSubview(subtitleLabel)
    }

    private func configureSegment() {
        segmentStackView.translatesAutoresizingMaskIntoConstraints = false
        segmentStackView.axis = .horizontal
        segmentStackView.alignment = .fill
        segmentStackView.spacing = 24

        segmentButtons = viewModel.segments.enumerated().map { index, title in
            let button = UIButton(type: .custom)
            button.tag = index
            button.setTitle(title, for: .normal)
            button.titleLabel?.font = AppFont.semibold(size: 12)
            button.adjustsImageWhenHighlighted = false
            button.contentHorizontalAlignment = .left
            button.addTarget(self, action: #selector(segmentButtonTapped(_:)), for: .touchUpInside)
            return button
        }
        segmentButtons.forEach(segmentStackView.addArrangedSubview)
        view.addSubview(segmentStackView)
        updateSegmentSelection()
    }

    private func configurePages() {
        pageContainerView.translatesAutoresizingMaskIntoConstraints = false
        pageControllers = viewModel.segmentPosts.map { posts in
            let viewController = HomePostsPageViewController(posts: posts)
            viewController.onMoreTapped = { [weak self] post in
                self?.showReport(post: post)
            }
            viewController.onPostSelected = { [weak self] homePost in
                self?.showPostDetail(homePost)
            }
            viewController.onAvatarTapped = { [weak self] homePost in
                self?.showAuthorProfile(homePost)
            }
            return viewController
        }

        addChild(pageViewController)
        pageViewController.dataSource = self
        pageViewController.delegate = self
        pageContainerView.addSubview(pageViewController.view)
        view.addSubview(pageContainerView)
        pageViewController.didMove(toParent: self)

        if let firstController = pageControllers.first {
            pageViewController.setViewControllers([firstController], direction: .forward, animated: false)
        }
    }

    private func configureLayout() {
        pageViewController.view.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            greetingLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 18),
            greetingLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: Constants.horizontalInset),
            greetingLabel.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -Constants.horizontalInset),

            subtitleLabel.topAnchor.constraint(equalTo: greetingLabel.bottomAnchor, constant: 6),
            subtitleLabel.leadingAnchor.constraint(equalTo: greetingLabel.leadingAnchor),
            subtitleLabel.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -Constants.horizontalInset),

            segmentStackView.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 12),
            segmentStackView.leadingAnchor.constraint(equalTo: subtitleLabel.leadingAnchor),
            segmentStackView.heightAnchor.constraint(equalToConstant: 28),

            pageContainerView.topAnchor.constraint(equalTo: segmentStackView.bottomAnchor, constant: 4),
            pageContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            pageContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            pageContainerView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),

            pageViewController.view.topAnchor.constraint(equalTo: pageContainerView.topAnchor),
            pageViewController.view.leadingAnchor.constraint(equalTo: pageContainerView.leadingAnchor),
            pageViewController.view.trailingAnchor.constraint(equalTo: pageContainerView.trailingAnchor),
            pageViewController.view.bottomAnchor.constraint(equalTo: pageContainerView.bottomAnchor)
        ])
    }

    @objc private func segmentButtonTapped(_ sender: UIButton) {
        sender.isHighlighted = false
        let newIndex = sender.tag
        guard newIndex != selectedIndex, pageControllers.indices.contains(newIndex) else {
            return
        }

        let direction: UIPageViewController.NavigationDirection = newIndex > selectedIndex ? .forward : .reverse
        selectedIndex = newIndex
        updateSegmentSelection()
        pageViewController.setViewControllers([pageControllers[newIndex]], direction: direction, animated: false)
    }

    private func updateSegmentSelection() {
        UIView.performWithoutAnimation {
            segmentButtons.enumerated().forEach { index, button in
                let isSelected = index == selectedIndex
                let title = viewModel.segments[index]
                let attributes: [NSAttributedString.Key: Any] = [
                    .font: AppFont.semibold(size: 12),
                    .foregroundColor: Constants.darkTextColor,
                    .underlineStyle: isSelected ? NSUnderlineStyle.single.rawValue : 0
                ]
                let attributedTitle = NSAttributedString(string: title, attributes: attributes)
                button.setAttributedTitle(attributedTitle, for: .normal)
                button.setAttributedTitle(attributedTitle, for: .highlighted)
                button.layoutIfNeeded()
            }
        }
    }

    private func showReport(post: HomePost) {
        let vc = ReportAlertController()
        vc.modalPresentationStyle = .overFullScreen
        vc.actionHandler = { [weak self] result in
            guard let self = self else { return }
            DispatchQueue.main.async {
                if result {
                    self.blockReceiverUser(post: post)
                } else {
                    let reportVC = ReportViewController()
                    self.navigationController?.pushViewController(reportVC, animated: true)
                }
            }
        }
        self.present(vc, animated: false)
    }

    private func blockReceiverUser(post: HomePost) {
        guard let currentUser = loadCurrentUser() else {
            AppToast.show(message: NSLocalizedString("Failed to block user.", comment: "Block user failure toast"), in: view)
            return
        }

        guard let receiverUser = post.sourcePost?.author else {
            AppToast.show(message: NSLocalizedString("Failed to block user.", comment: "Block user failure toast"), in: view)
            return
        }

        guard currentUser.id != receiverUser.id else {
            AppToast.show(message: NSLocalizedString("You cannot block yourself.", comment: "Block self toast"), in: view)
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

    private func showPostDetail(_ homePost: HomePost) {
        guard let sourcePost = homePost.sourcePost else {
            return
        }

        let viewController = PostDetailViewController(post: sourcePost, homePost: homePost)
        viewController.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(viewController, animated: true)
    }

    private func showAuthorProfile(_ homePost: HomePost) {
        guard let author = homePost.sourcePost?.author else {
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

    private func loadPosts() {
        guard let userIdString = UserDefaults.standard.string(forKey: CurrentUserIdKey),
              let userId = UUID(uuidString: userIdString),
              case .success(let currentUser) = userRepository.fetchUser(id: userId),
              case .success(let posts) = postRepository.fetchHomeFeed(for: currentUser) else {
            greetingLabel.text = viewModel.greetingTitle
            return
        }

        updateGreeting(with: currentUser)

        let homePosts = posts.enumerated().map { index, post in
            makeHomePost(from: post, index: index)
        }
        let followingHomePosts = makeFollowingHomePosts(from: posts, currentUser: currentUser)

        AppLoading.show(in: self.view) { [weak self] in
            guard let self = self else { return }
            self.pageControllers.enumerated().forEach { index, controller in
                let pagePosts = index == 1 ? followingHomePosts : homePosts
                controller.updatePosts(pagePosts)
            }
        }
    }

    private func makeFollowingHomePosts(from posts: [Post], currentUser: User) -> [HomePost] {
        guard case .success(let followingUsers) = userRepository.fetchFollowingUsers(for: currentUser),
              !followingUsers.isEmpty else {
            return []
        }

        let followingUserIds = Set(followingUsers.map(\.id))
        return posts
            .filter { post in
                guard let authorId = post.author?.id else {
                    return false
                }
                return followingUserIds.contains(authorId)
            }
            .enumerated()
            .map { index, post in
                makeHomePost(from: post, index: index)
            }
    }

    private func updateGreeting(with user: User) {
        guard let nickname = cleanedText(user.nickname) else {
            greetingLabel.text = viewModel.greetingTitle
            return
        }

        greetingLabel.text = String(
            format: NSLocalizedString("Good Morning, %@", comment: "Home greeting with user name"),
            nickname
        )
    }

    @objc private func handlePostDidPublish() {
        loadPosts()
    }

    @objc private func handleUserRelationDidChange() {
        loadPosts()
    }

    private func makeHomePost(from post: Post, index: Int) -> HomePost {
        let images = makePostImages(for: post)
        let author = post.author
        let usePurpleStyle = index.isMultiple(of: 2)
        let primaryTextColor = usePurpleStyle ? UIColor.white : Constants.darkTextColor
        let secondaryTextColor = usePurpleStyle ? UIColor.white.withAlphaComponent(0.78) : Constants.mutedTextColor

        return HomePost(
            sourcePost: post,
            author: cleanedText(author?.nickname) ?? NSLocalizedString("Unknown", comment: "Unknown post author"),
            school: cleanedText(author?.school) ?? cleanedText(post.addressText) ?? NSLocalizedString("Campus", comment: "Fallback school"),
            time: makeRelativeTime(from: post.createdAt),
            body: post.content,
            avatarImage: makeAvatarImage(from: author?.avatarLocalPath),
            heroImage: images.first,
            thumbnailImages: images,
            isHot: post.likeCount >= Constants.hotLikeThreshold,
            backgroundColor: usePurpleStyle ? Constants.purpleColor : Constants.limeColor,
            primaryTextColor: primaryTextColor,
            secondaryTextColor: secondaryTextColor,
            isCurrentUserPost: author?.id == loadCurrentUser()?.id
        )
    }

    private func makePostImages(for post: Post) -> [UIImage] {
        guard case .success(let postImages) = postRepository.fetchImages(for: post) else {
            return []
        }

        return postImages.compactMap { image in
            UIImage.sandboxOrAssetImage(named: image.localPath, documentsSubdirectory: "PostImages")
        }
    }

    private func makeAvatarImage(from storedPath: String?) -> UIImage? {
        UIImage.sandboxOrAssetImage(named: storedPath, documentsSubdirectory: "Avatars", fallbackName: "user_icon")
    }

    private func makeRelativeTime(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: date, relativeTo: Date())
    }

    private func cleanedText(_ text: String?) -> String? {
        let value = text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return value.isEmpty ? nil : value
    }
}

extension HomeViewController: UIPageViewControllerDataSource, UIPageViewControllerDelegate {
    func pageViewController(
        _ pageViewController: UIPageViewController,
        viewControllerBefore viewController: UIViewController
    ) -> UIViewController? {
        guard let index = pageControllers.firstIndex(where: { $0 === viewController }), index > 0 else {
            return nil
        }
        return pageControllers[index - 1]
    }

    func pageViewController(
        _ pageViewController: UIPageViewController,
        viewControllerAfter viewController: UIViewController
    ) -> UIViewController? {
        guard let index = pageControllers.firstIndex(where: { $0 === viewController }), index < pageControllers.count - 1 else {
            return nil
        }
        return pageControllers[index + 1]
    }

    func pageViewController(
        _ pageViewController: UIPageViewController,
        didFinishAnimating finished: Bool,
        previousViewControllers: [UIViewController],
        transitionCompleted completed: Bool
    ) {
        guard completed,
              let currentController = pageViewController.viewControllers?.first,
              let index = pageControllers.firstIndex(where: { $0 === currentController }) else {
            return
        }
        selectedIndex = index
        updateSegmentSelection()
    }
}

private final class HomePostsPageViewController: UIViewController {
    private var posts: [HomePost]
    private let tableView = UITableView(frame: .zero, style: .plain)
    var onMoreTapped: ((HomePost) -> Void)?
    var onPostSelected: ((HomePost) -> Void)?
    var onAvatarTapped: ((HomePost) -> Void)?

    init(posts: [HomePost]) {
        self.posts = posts
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        configureTableView()
        configureLayout()
        updateEmptyState()
    }

    private func configureTableView() {
        view.backgroundColor = HomeViewController.Constants.backgroundColor
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.showsVerticalScrollIndicator = false
        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 68, right: 0)
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 300
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(HomePostTableViewCell.self, forCellReuseIdentifier: HomePostTableViewCell.reuseIdentifier)
        view.addSubview(tableView)
    }

    private func configureLayout() {
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func updateEmptyState() {
        tableView.backgroundView = posts.isEmpty ? EmptyView(frame: tableView.bounds) : nil
        tableView.isScrollEnabled = !posts.isEmpty
    }

    func updatePosts(_ posts: [HomePost]) {
        self.posts = posts
        tableView.reloadData()
        updateEmptyState()
    }
}

extension HomePostsPageViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        posts.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: HomePostTableViewCell.reuseIdentifier,
            for: indexPath
        ) as? HomePostTableViewCell else {
            return UITableViewCell()
        }
        let post = posts[indexPath.row]
        cell.configure(post: post)
        cell.onMoreTapped = { [weak self] in
            guard let self = self else { return }
            self.onMoreTapped?(post)
        }
        cell.onAvatarTapped = { [weak self] in
            self?.onAvatarTapped?(post)
        }
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard posts.indices.contains(indexPath.row) else {
            return
        }
        onPostSelected?(posts[indexPath.row])
    }
}

private final class HomePostTableViewCell: UITableViewCell {
    static let reuseIdentifier = "HomePostTableViewCell"

    private let cardView = UIView()
    private let avatarImageView = UIImageView()
    private let authorLabel = UILabel()
    private let metaLabel = UILabel()
    private let moreButton = UIButton(type: .custom)
    private let bodyLabel = UILabel()
    private let heroImageView = UIImageView()
    private let thumbnailsStackView = UIStackView()
    private let hotImageView = UIImageView()
    private var compactHeroHeightConstraint: NSLayoutConstraint?
    private var expandedHeroHeightConstraint: NSLayoutConstraint?
    private var thumbnailsTopConstraint: NSLayoutConstraint?
    private var thumbnailsHeightConstraint: NSLayoutConstraint?
    private var thumbnailsBottomConstraint: NSLayoutConstraint?
    private var heroBottomConstraint: NSLayoutConstraint?
    var onMoreTapped: (() -> Void)?
    var onAvatarTapped: (() -> Void)?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        configureViews()
        configureLayout()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        thumbnailsStackView.arrangedSubviews.forEach { view in
            thumbnailsStackView.removeArrangedSubview(view)
            view.removeFromSuperview()
        }
        thumbnailsStackView.isHidden = false
        deactivateImageLayoutConstraints()
        expandedHeroHeightConstraint?.isActive = false
        compactHeroHeightConstraint?.isActive = true
        thumbnailsTopConstraint?.isActive = true
        thumbnailsHeightConstraint?.isActive = true
        thumbnailsBottomConstraint?.isActive = true
        onMoreTapped = nil
        onAvatarTapped = nil
    }

    func configure(post: HomePost) {
        cardView.backgroundColor = post.backgroundColor
        avatarImageView.image = post.avatarImage ?? UIImage(named: "user_icon")
        authorLabel.text = post.author
        authorLabel.textColor = post.primaryTextColor
        metaLabel.text = "\(post.school)  -  \(post.time)"
        metaLabel.textColor = post.secondaryTextColor
        bodyLabel.text = post.body
        bodyLabel.textColor = post.primaryTextColor
        heroImageView.image = post.heroImage ?? UIImage(named: "photo")
        hotImageView.isHidden = !post.isHot
        moreButton.isHidden = post.isCurrentUserPost

        let shouldExpandHero = post.thumbnailImages.count <= 1
        thumbnailsStackView.isHidden = shouldExpandHero
        updateImageLayout(expandsHero: shouldExpandHero)

        guard !shouldExpandHero else {
            return
        }

        post.thumbnailImages.map(makeThumbnailImageView(image:)).forEach(thumbnailsStackView.addArrangedSubview)
    }

    private func updateImageLayout(expandsHero: Bool) {
        deactivateImageLayoutConstraints()
        compactHeroHeightConstraint?.isActive = !expandsHero
        expandedHeroHeightConstraint?.isActive = expandsHero
        thumbnailsTopConstraint?.isActive = !expandsHero
        thumbnailsHeightConstraint?.isActive = !expandsHero
        thumbnailsBottomConstraint?.isActive = !expandsHero
        heroBottomConstraint?.isActive = expandsHero
    }

    private func deactivateImageLayoutConstraints() {
        compactHeroHeightConstraint?.isActive = false
        expandedHeroHeightConstraint?.isActive = false
        thumbnailsTopConstraint?.isActive = false
        thumbnailsHeightConstraint?.isActive = false
        thumbnailsBottomConstraint?.isActive = false
        heroBottomConstraint?.isActive = false
    }

    private func configureViews() {
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        selectionStyle = .none

        cardView.translatesAutoresizingMaskIntoConstraints = false
        cardView.layer.cornerRadius = 18
        cardView.clipsToBounds = true

        avatarImageView.translatesAutoresizingMaskIntoConstraints = false
        avatarImageView.contentMode = .scaleAspectFill
        avatarImageView.layer.cornerRadius = 19
        avatarImageView.layer.borderWidth = 1.5
        avatarImageView.layer.borderColor = UIColor.white.cgColor
        avatarImageView.clipsToBounds = true
        avatarImageView.isUserInteractionEnabled = true
        avatarImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(avatarTapped)))

        authorLabel.translatesAutoresizingMaskIntoConstraints = false
        authorLabel.font = AppFont.bold(size: 13)

        metaLabel.translatesAutoresizingMaskIntoConstraints = false
        metaLabel.font = AppFont.medium(size: 10)

        moreButton.translatesAutoresizingMaskIntoConstraints = false
        moreButton.setImage(UIImage(named: "more_gray") ?? UIImage(systemName: "ellipsis"), for: .normal)
        moreButton.imageView?.contentMode = .scaleAspectFit
        moreButton.addTarget(self, action: #selector(moreButtonTapped), for: .touchUpInside)

        bodyLabel.translatesAutoresizingMaskIntoConstraints = false
        bodyLabel.font = AppFont.medium(size: 12)
        bodyLabel.numberOfLines = 0

        heroImageView.translatesAutoresizingMaskIntoConstraints = false
        heroImageView.contentMode = .scaleAspectFill
        heroImageView.layer.cornerRadius = 8
        heroImageView.clipsToBounds = true

        thumbnailsStackView.translatesAutoresizingMaskIntoConstraints = false
        thumbnailsStackView.axis = .horizontal
        thumbnailsStackView.distribution = .fillEqually
        thumbnailsStackView.spacing = 4

        hotImageView.translatesAutoresizingMaskIntoConstraints = false
        hotImageView.image = UIImage(named: "hot")
        hotImageView.contentMode = .scaleAspectFit

        contentView.addSubview(cardView)
        cardView.addSubview(avatarImageView)
        cardView.addSubview(authorLabel)
        cardView.addSubview(metaLabel)
        cardView.addSubview(moreButton)
        cardView.addSubview(bodyLabel)
        cardView.addSubview(heroImageView)
        cardView.addSubview(thumbnailsStackView)
        cardView.addSubview(hotImageView)
    }

    private func configureLayout() {
        compactHeroHeightConstraint = heroImageView.heightAnchor.constraint(equalTo: heroImageView.widthAnchor, multiplier: 0.48)
        expandedHeroHeightConstraint = heroImageView.heightAnchor.constraint(equalTo: heroImageView.widthAnchor, multiplier: 0.48, constant: 62)
        thumbnailsTopConstraint = thumbnailsStackView.topAnchor.constraint(equalTo: heroImageView.bottomAnchor, constant: 4)
        thumbnailsHeightConstraint = thumbnailsStackView.heightAnchor.constraint(equalToConstant: 58)
        thumbnailsBottomConstraint = thumbnailsStackView.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -12)
        heroBottomConstraint = heroImageView.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -12)

        compactHeroHeightConstraint?.isActive = true
        thumbnailsTopConstraint?.isActive = true
        thumbnailsHeightConstraint?.isActive = true
        thumbnailsBottomConstraint?.isActive = true

        NSLayoutConstraint.activate([
            cardView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6),
            cardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: HomeViewController.Constants.horizontalInset),
            cardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -HomeViewController.Constants.horizontalInset),
            cardView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10),

            avatarImageView.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 12),
            avatarImageView.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 12),
            avatarImageView.widthAnchor.constraint(equalToConstant: 38),
            avatarImageView.heightAnchor.constraint(equalToConstant: 38),

            authorLabel.topAnchor.constraint(equalTo: avatarImageView.topAnchor, constant: 2),
            authorLabel.leadingAnchor.constraint(equalTo: avatarImageView.trailingAnchor, constant: 10),
            authorLabel.trailingAnchor.constraint(lessThanOrEqualTo: moreButton.leadingAnchor, constant: -12),

            metaLabel.topAnchor.constraint(equalTo: authorLabel.bottomAnchor, constant: 3),
            metaLabel.leadingAnchor.constraint(equalTo: authorLabel.leadingAnchor),
            metaLabel.trailingAnchor.constraint(lessThanOrEqualTo: moreButton.leadingAnchor, constant: -12),

            moreButton.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 10),
            moreButton.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -8),
            moreButton.widthAnchor.constraint(equalToConstant: 32),
            moreButton.heightAnchor.constraint(equalToConstant: 32),

            bodyLabel.topAnchor.constraint(equalTo: avatarImageView.bottomAnchor, constant: 12),
            bodyLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 12),
            bodyLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -12),

            heroImageView.topAnchor.constraint(equalTo: bodyLabel.bottomAnchor, constant: 10),
            heroImageView.leadingAnchor.constraint(equalTo: bodyLabel.leadingAnchor),
            heroImageView.trailingAnchor.constraint(equalTo: bodyLabel.trailingAnchor),

            thumbnailsStackView.leadingAnchor.constraint(equalTo: heroImageView.leadingAnchor),
            thumbnailsStackView.trailingAnchor.constraint(equalTo: heroImageView.trailingAnchor),

            hotImageView.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -2),
            hotImageView.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -4),
            hotImageView.widthAnchor.constraint(equalToConstant: 66),
            hotImageView.heightAnchor.constraint(equalToConstant: 66)
        ])
    }

    private func makeThumbnailImageView(image: UIImage) -> UIImageView {
        let imageView = UIImageView()
        imageView.image = image
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        return imageView
    }

    @objc private func moreButtonTapped() {
        onMoreTapped?()
    }

    @objc private func avatarTapped() {
        onAvatarTapped?()
    }
}
