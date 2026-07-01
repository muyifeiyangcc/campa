import SnapKit
import UIKit

final class ProfileViewController: BaseViewController {
    private enum Constants {
        static let backgroundColor = UIColor(red: 0.98, green: 0.93, blue: 0.86, alpha: 1.0)
        static let purpleColor = UIColor(red: 0.69, green: 0.59, blue: 0.96, alpha: 1.0)
        static let darkTextColor = UIColor(red: 0.28, green: 0.02, blue: 0.01, alpha: 1.0)
        static let mutedTextColor = UIColor(red: 0.42, green: 0.36, blue: 0.32, alpha: 1.0)
    }

    private let viewModel: ProfileViewModel
    private let userRepository: UserRepository
    private let postRepository: PostRepository
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let headerImageView = UIImageView()
    private let profilePanelView = UIView()
    private let avatarImageView = UIImageView()
    private let nameLabel = UILabel()
    private let schoolLabel = UILabel()
    private let locationIconView = UIImageView()
    private let locationLabel = UILabel()
    private let statsStackView = UIStackView()
    private let followingCountLabel = UILabel()
    private let followersCountLabel = UILabel()
    private let postsCountLabel = UILabel()
    private let postCardView = UIView()
    private let postAvatarImageView = UIImageView()
    private let postNameLabel = UILabel()
    private let postMetaLabel = UILabel()
    private let postBodyLabel = UILabel()
    private let postHeroImageView = UIImageView()
    private let thumbnailStackView = UIStackView()
    private let emptyView = EmptyView()
    private var postCardBottomConstraint: Constraint?
    private var emptyBottomConstraint: Constraint?
    private var thumbnailTopConstraint: Constraint?
    private var thumbnailHeightConstraint: Constraint?
    private var thumbnailBottomConstraint: Constraint?
    private var heroBottomConstraint: Constraint?

    init(
        viewModel: ProfileViewModel = ProfileViewModel(),
        userRepository: UserRepository = UserRepository(),
        postRepository: PostRepository = PostRepository()
    ) {
        self.viewModel = viewModel
        self.userRepository = userRepository
        self.postRepository = postRepository
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configure()
        configureHeader()
        configureProfilePanel()
        configurePostCard()
        configureLayout()
        updateCurrentCity()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        loadCurrentUserProfile()
        updateCurrentCity()
    }

    override func rightAction() {
        let vc = SettingsViewController()
        vc.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(vc, animated: true)
    }
    
    private func configure() {
        view.backgroundColor = Constants.backgroundColor
        self.navType = .titleRightBtn
        self.setTitleAndRight(title: nil, right: "set", rightSize: CGSize(width: 30, height: 30))
        scrollView.contentInsetAdjustmentBehavior = .never
        scrollView.showsVerticalScrollIndicator = false
        scrollView.alwaysBounceVertical = true
    }

    private func configureHeader() {
        headerImageView.translatesAutoresizingMaskIntoConstraints = false
        headerImageView.contentMode = .scaleAspectFill
        headerImageView.clipsToBounds = true
        headerImageView.backgroundColor = .white
    }

    private func configureProfilePanel() {
        profilePanelView.translatesAutoresizingMaskIntoConstraints = false
        profilePanelView.backgroundColor = Constants.backgroundColor
        profilePanelView.layer.cornerRadius = 34
        profilePanelView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]

        avatarImageView.translatesAutoresizingMaskIntoConstraints = false
        avatarImageView.image = defaultAvatarImage()
        avatarImageView.contentMode = .scaleAspectFill
        avatarImageView.layer.cornerRadius = 46
        avatarImageView.clipsToBounds = true
        avatarImageView.backgroundColor = .white
        
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.text = viewModel.name
        nameLabel.font = AppFont.bold(size: 26)
        nameLabel.textColor = Constants.darkTextColor

        schoolLabel.translatesAutoresizingMaskIntoConstraints = false
        schoolLabel.text = viewModel.school
        schoolLabel.font = AppFont.semibold(size: 20)
        schoolLabel.textColor = Constants.mutedTextColor
        schoolLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        locationIconView.translatesAutoresizingMaskIntoConstraints = false
        locationIconView.image = UIImage(named: "location")
        locationIconView.contentMode = .scaleAspectFit
        locationIconView.tintColor = Constants.mutedTextColor

        locationLabel.translatesAutoresizingMaskIntoConstraints = false
        locationLabel.text = viewModel.location
        locationLabel.font = AppFont.medium(size: 14)
        locationLabel.textColor = Constants.mutedTextColor
        locationLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        statsStackView.translatesAutoresizingMaskIntoConstraints = false
        statsStackView.axis = .horizontal
        statsStackView.alignment = .center
        statsStackView.distribution = .fillEqually
        statsStackView.spacing = 24

        [
            makeStatView(
                countLabel: followingCountLabel,
                count: viewModel.followingCount,
                title: viewModel.followingTitle,
                action: #selector(handleFollowingTapped)
            ),
            makeStatView(
                countLabel: followersCountLabel,
                count: viewModel.followersCount,
                title: viewModel.followersTitle,
                action: #selector(handleFollowersTapped)
            ),
            makeStatView(countLabel: postsCountLabel, count: viewModel.postsCount, title: viewModel.postsTitle)
        ].forEach(statsStackView.addArrangedSubview)
    }

    private func configurePostCard() {
        postCardView.translatesAutoresizingMaskIntoConstraints = false
        postCardView.backgroundColor = Constants.purpleColor
        postCardView.layer.cornerRadius = 24
        postCardView.clipsToBounds = true

        postAvatarImageView.translatesAutoresizingMaskIntoConstraints = false
        postAvatarImageView.image = defaultAvatarImage()
        postAvatarImageView.backgroundColor = .white
        postAvatarImageView.contentMode = .scaleAspectFill
        postAvatarImageView.layer.cornerRadius = 27
        postAvatarImageView.layer.borderColor = UIColor.white.cgColor
        postAvatarImageView.layer.borderWidth = 2
        postAvatarImageView.clipsToBounds = true

        postNameLabel.translatesAutoresizingMaskIntoConstraints = false
        postNameLabel.text = viewModel.postAuthor
        postNameLabel.font = AppFont.semibold(size: 20)
        postNameLabel.textColor = .white

        postMetaLabel.translatesAutoresizingMaskIntoConstraints = false
        postMetaLabel.text = "\(viewModel.postSchool)  •  \(viewModel.postTime)"
        postMetaLabel.font = AppFont.medium(size: 12)
        postMetaLabel.textColor = UIColor.white.withAlphaComponent(0.82)

        postBodyLabel.translatesAutoresizingMaskIntoConstraints = false
        postBodyLabel.text = viewModel.postText
        postBodyLabel.font = AppFont.medium(size: 14)
        postBodyLabel.textColor = .white
        postBodyLabel.numberOfLines = 0

        postHeroImageView.translatesAutoresizingMaskIntoConstraints = false
        postHeroImageView.contentMode = .scaleAspectFill
        postHeroImageView.clipsToBounds = true
        postHeroImageView.layer.cornerRadius = 8
        postHeroImageView.backgroundColor = .blue
        thumbnailStackView.translatesAutoresizingMaskIntoConstraints = false
        thumbnailStackView.axis = .horizontal
        thumbnailStackView.distribution = .fillEqually
        thumbnailStackView.spacing = 4

        [
            UIColor(red: 0.70, green: 0.80, blue: 0.76, alpha: 1.0),
            UIColor(red: 0.78, green: 0.84, blue: 0.85, alpha: 1.0),
            UIColor(red: 0.58, green: 0.70, blue: 0.44, alpha: 1.0)
        ].map(makeThumbnailView(color:)).forEach(thumbnailStackView.addArrangedSubview)
    }

    private func configureLayout() {
        view.addSubview(headerImageView)
        view.addSubview(profilePanelView)
        view.addSubview(avatarImageView)
        profilePanelView.addSubview(statsStackView)
        profilePanelView.addSubview(nameLabel)
        profilePanelView.addSubview(schoolLabel)
        profilePanelView.addSubview(locationIconView)
        profilePanelView.addSubview(locationLabel)
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        contentView.addSubview(postCardView)
        contentView.addSubview(emptyView)
        postCardView.addSubview(postAvatarImageView)
        postCardView.addSubview(postNameLabel)
        postCardView.addSubview(postMetaLabel)
        postCardView.addSubview(postBodyLabel)
        postCardView.addSubview(postHeroImageView)
        postCardView.addSubview(thumbnailStackView)
        view.bringSubviewToFront(navBar)

        headerImageView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(view.snp.height).multipliedBy(0.36)
        }

        profilePanelView.snp.makeConstraints { make in
            make.top.equalTo(headerImageView.snp.bottom).offset(-42)
            make.leading.trailing.bottom.equalToSuperview()
        }

        avatarImageView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(62)
            make.centerY.equalTo(profilePanelView.snp.top).offset(-16)
            make.size.equalTo(92)
        }

        scrollView.snp.makeConstraints { make in
            make.top.equalTo(locationLabel.snp.bottom).offset(34)
            make.leading.trailing.bottom.equalToSuperview()
        }

        contentView.snp.makeConstraints { make in
            make.edges.equalTo(scrollView.contentLayoutGuide)
            make.width.equalTo(scrollView.frameLayoutGuide)
        }

        statsStackView.snp.makeConstraints { make in
            make.top.equalTo(profilePanelView.snp.top).offset(16)
            make.leading.equalTo(avatarImageView.snp.trailing).offset(24)
            make.trailing.equalTo(profilePanelView.snp.trailing).inset(26)
            make.height.equalTo(54)
        }

        nameLabel.snp.makeConstraints { make in
            make.top.equalTo(avatarImageView.snp.bottom).offset(16)
            make.leading.equalTo(profilePanelView.snp.leading).offset(25)
            make.trailing.lessThanOrEqualTo(statsStackView.snp.leading).offset(-16)
        }

        schoolLabel.snp.makeConstraints { make in
            make.top.equalTo(nameLabel.snp.bottom).offset(8)
            make.leading.equalTo(nameLabel.snp.leading)
            make.trailing.lessThanOrEqualTo(locationIconView.snp.leading).offset(-12)
        }

        locationIconView.snp.makeConstraints { make in
            make.leading.equalTo(schoolLabel.snp.trailing).offset(12)
            make.centerY.equalTo(schoolLabel.snp.centerY)
            make.size.equalTo(18)
        }

        locationLabel.snp.makeConstraints { make in
            make.leading.equalTo(locationIconView.snp.trailing).offset(6)
            make.centerY.equalTo(schoolLabel.snp.centerY)
            make.trailing.lessThanOrEqualTo(profilePanelView.snp.trailing).inset(26)
        }

        postCardView.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(30)
            postCardBottomConstraint = make.bottom.equalToSuperview().inset(108).constraint
        }

        emptyView.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(30)
            make.height.equalTo(260)
            emptyBottomConstraint = make.bottom.equalToSuperview().inset(108).constraint
        }
        emptyBottomConstraint?.deactivate()

        postAvatarImageView.snp.makeConstraints { make in
            make.top.leading.equalToSuperview().offset(22)
            make.size.equalTo(54)
        }

        postNameLabel.snp.makeConstraints { make in
            make.top.equalTo(postAvatarImageView.snp.top).offset(2)
            make.leading.equalTo(postAvatarImageView.snp.trailing).offset(14)
            make.trailing.lessThanOrEqualToSuperview().inset(18)
        }

        postMetaLabel.snp.makeConstraints { make in
            make.top.equalTo(postNameLabel.snp.bottom).offset(4)
            make.leading.equalTo(postNameLabel.snp.leading)
            make.trailing.lessThanOrEqualToSuperview().inset(18)
        }

        postBodyLabel.snp.makeConstraints { make in
            make.top.equalTo(postAvatarImageView.snp.bottom).offset(20)
            make.leading.trailing.equalToSuperview().inset(22)
        }

        postHeroImageView.snp.makeConstraints { make in
            make.top.equalTo(postBodyLabel.snp.bottom).offset(18)
            make.leading.trailing.equalTo(postBodyLabel)
            make.height.equalTo(postHeroImageView.snp.width).multipliedBy(0.56)
        }

        thumbnailStackView.snp.makeConstraints { make in
            thumbnailTopConstraint = make.top.equalTo(postHeroImageView.snp.bottom).offset(4).constraint
            make.leading.trailing.equalTo(postHeroImageView)
            thumbnailHeightConstraint = make.height.equalTo(postHeroImageView.snp.height).multipliedBy(0.32).constraint
            thumbnailBottomConstraint = make.bottom.equalToSuperview().inset(22).constraint
        }

        postHeroImageView.snp.makeConstraints { make in
            heroBottomConstraint = make.bottom.equalToSuperview().inset(22).constraint
        }
        heroBottomConstraint?.deactivate()

        emptyView.isHidden = true
    }

    private func makeStatView(
        countLabel: UILabel,
        count: String,
        title: String,
        action: Selector? = nil
    ) -> UIView {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.spacing = 2

        countLabel.text = count
        countLabel.font = AppFont.semibold(size: 25)
        countLabel.textColor = Constants.darkTextColor
        countLabel.textAlignment = .center

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = AppFont.medium(size: 12)
        titleLabel.textColor = Constants.darkTextColor
        titleLabel.textAlignment = .center

        stackView.addArrangedSubview(countLabel)
        stackView.addArrangedSubview(titleLabel)

        if let action {
            let tapGesture = UITapGestureRecognizer(target: self, action: action)
            stackView.addGestureRecognizer(tapGesture)
            stackView.isUserInteractionEnabled = true
        }

        return stackView
    }

    @objc private func handleFollowingTapped() {
        let vc = FollowViewController()
        vc.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(vc, animated: true)
    }

    @objc private func handleFollowersTapped() {
        let vc = FollowersViewController()
        vc.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(vc, animated: true)
    }

    private func makeThumbnailView(color: UIColor) -> UIView {
        let view = UIView()
        view.backgroundColor = color
        view.layer.cornerRadius = 4
        view.clipsToBounds = true
        return view
    }

    private func loadCurrentUserProfile() {
        guard let userIdString = UserDefaults.standard.string(forKey: CurrentUserIdKey),
              let userId = UUID(uuidString: userIdString),
              case .success(let user) = userRepository.fetchUser(id: userId) else {
            return
        }

        apply(user: user)
        loadStats(for: user)
        loadFirstPost(for: user)
    }

    private func loadStats(for user: User) {
        if case .success(let followingCount) = userRepository.countFollowingUsers(for: user) {
            viewModel.followingCount = "\(followingCount)"
        } else {
            viewModel.followingCount = "0"
        }

        if case .success(let followersCount) = userRepository.countFollowersUsers(for: user) {
            viewModel.followersCount = "\(followersCount)"
        } else {
            viewModel.followersCount = "0"
        }

        if case .success(let postsCount) = postRepository.countPosts(for: user) {
            viewModel.postsCount = "\(postsCount)"
        } else {
            viewModel.postsCount = "0"
        }

        followingCountLabel.text = viewModel.followingCount
        followersCountLabel.text = viewModel.followersCount
        postsCountLabel.text = viewModel.postsCount
    }

    private func apply(user: User) {
        nameLabel.text = user.nickname
        schoolLabel.text = schoolCleanedText(user.location) ?? viewModel.school
        postNameLabel.text = user.nickname

        let avatarImage = makeAvatarImage(from: user.avatarLocalPath)
        headerImageView.image = avatarImage
        avatarImageView.image = avatarImage
        postAvatarImageView.image = avatarImage
    }

    private func updateCurrentCity() {
        CurrentCityProvider.shared.requestCurrentCity { [weak self] city in
            guard let self, let city else { return }
            DispatchQueue.main.async {
                self.locationLabel.text = city
            }
        }
    }

    private func makeAvatarImage(from storedPath: String?) -> UIImage? {
        UIImage.sandboxOrAssetImage(named: storedPath, documentsSubdirectory: "Avatars") ?? defaultAvatarImage()
    }

    private func defaultAvatarImage() -> UIImage? {
        UIImage(named: "muser") ?? UIImage(named: "user_icon")
    }

    private func schoolCleanedText(_ text: String?) -> String? {
        let value = text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return value.isEmpty ? nil : value
    }

    private func loadFirstPost(for user: User) {
        guard case .success(let posts) = postRepository.fetchPosts(for: user),
              let post = posts.first else {
            showEmptyPost()
            return
        }

        showPostCard()
        configurePost(post, user: user)
    }

    private func configurePost(_ post: Post, user: User) {
        postNameLabel.text = user.nickname
        postMetaLabel.text = "\(user.school ?? post.addressText ?? viewModel.postSchool)  •  \(makeRelativeTime(from: post.createdAt))"
        postBodyLabel.text = post.content

        let images = makePostImages(for: post)
        postHeroImageView.image = images.first ?? UIImage(named: "photo")

        thumbnailStackView.arrangedSubviews.forEach { view in
            thumbnailStackView.removeArrangedSubview(view)
            view.removeFromSuperview()
        }

        images.dropFirst().forEach { image in
            thumbnailStackView.addArrangedSubview(makeThumbnailImageView(image: image))
        }
        let shouldHideThumbnails = images.count <= 1
        updateThumbnailLayout(isHidden: shouldHideThumbnails)
    }

    private func updateThumbnailLayout(isHidden: Bool) {
        thumbnailStackView.isHidden = isHidden

        if isHidden {
            thumbnailTopConstraint?.deactivate()
            thumbnailHeightConstraint?.deactivate()
            thumbnailBottomConstraint?.deactivate()
            heroBottomConstraint?.activate()
        } else {
            heroBottomConstraint?.deactivate()
            thumbnailTopConstraint?.activate()
            thumbnailHeightConstraint?.activate()
            thumbnailBottomConstraint?.activate()
        }
    }

    private func showEmptyPost() {
        postCardView.isHidden = true
        emptyView.isHidden = false
        postCardBottomConstraint?.deactivate()
        emptyBottomConstraint?.activate()
    }

    private func showPostCard() {
        postCardView.isHidden = false
        emptyView.isHidden = true
        emptyBottomConstraint?.deactivate()
        postCardBottomConstraint?.activate()
    }

    private func makePostImages(for post: Post) -> [UIImage] {
        guard case .success(let postImages) = postRepository.fetchImages(for: post) else {
            return []
        }

        return postImages.compactMap { image in
            UIImage.sandboxOrAssetImage(named: image.localPath, documentsSubdirectory: "PostImages")
        }
    }

    private func makeRelativeTime(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: date, relativeTo: Date())
    }

    private func makeThumbnailImageView(image: UIImage) -> UIImageView {
        let imageView = UIImageView()
        imageView.image = image
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 4
        return imageView
    }

    private func cleanedText(_ text: String?) -> String? {
        let value = text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !value.isEmpty else {
            return nil
        }

        if value.hasPrefix("/") {
            return value
        }

        if let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            return documentsURL
                .appendingPathComponent("Avatars", isDirectory: true)
                .appendingPathComponent(value)
                .path
        }
        return value
    }
}
