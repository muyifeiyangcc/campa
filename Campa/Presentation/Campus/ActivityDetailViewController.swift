import UIKit

struct ActivityDetailData {
    let title: String
    let dateText: String
    let locationText: String
    let imageNames: [String]
    let imagePaths: [String]
}

final class ActivityDetailViewController: BaseViewController {
    private enum Constants {
        static let backgroundColor = UIColor(red: 0.98, green: 0.93, blue: 0.86, alpha: 1.0)
        static let darkTextColor = UIColor(red: 52/255.0, green: 4/255, blue: 4/255.0, alpha: 1.0)
        static let mutedTextColor = UIColor(red: 0.42, green: 0.36, blue: 0.32, alpha: 1.0)
        static let burgundyColor = UIColor(red: 52/255.0, green: 4/255.0, blue: 4/255.0, alpha: 1.0)
        static let horizontalInset: CGFloat = 28
    }

    private let activity: Activity?
    private let displayData: ActivityDetailData?
    private let activityRepository: ActivityRepository
    private let userRepository: UserRepository
    private var images: [UIImage] = []

    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let titleLabel = UILabel()
    private let imageCollectionView: UICollectionView
    private let infoCardView = UIView()
    private let activityTitleLabel = UILabel()
    private let dateLabel = UILabel()
    private let locationIconView = UIImageView()
    private let locationLabel = UILabel()
    private let joinButton = UIButton(type: .custom)
    private let participatedLabel = UILabel()

    init(
        activity: Activity? = nil,
        displayData: ActivityDetailData? = nil,
        activityRepository: ActivityRepository = ActivityRepository(),
        userRepository: UserRepository = UserRepository()
    ) {
        self.activity = activity
        self.displayData = displayData
        self.activityRepository = activityRepository
        self.userRepository = userRepository

        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 16
        layout.minimumInteritemSpacing = 16
        imageCollectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)

        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        configureView()
        configureScrollView()
        configureHeader()
        configureCollectionView()
        configureInfoCard()
        configureLayout()
        applyActivity()
    }

    private func configureView() {
        view.backgroundColor = Constants.backgroundColor
        changeNavbar(.backRightBtn)
        setTitleAndRight(title: nil, right: "more", rightSize: CGSize(width: 36, height: 36))
    }

    override func rightAction() {
        let vc = ReportAlertController()
        vc.modalPresentationStyle = .overFullScreen
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
        self.present(vc, animated: false)
    }

    private func blockReceiverUser() {
        guard let currentUser = loadCurrentUser() else {
            AppToast.show(message: NSLocalizedString("Failed to block user.", comment: "Block user failure toast"), in: view)
            return
        }

        guard let receiverUser = activity?.author else {
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

    private func configureScrollView() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.backgroundColor = .clear
        scrollView.showsVerticalScrollIndicator = false
        scrollView.alwaysBounceVertical = true

        contentView.translatesAutoresizingMaskIntoConstraints = false
        contentView.backgroundColor = .clear

        view.insertSubview(scrollView, at: 0)
        scrollView.addSubview(contentView)
    }

    private func configureHeader() {
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = NSLocalizedString("Recent Activities", comment: "Activity detail title")
        titleLabel.font = AppFont.bold(size: 20)
        titleLabel.textColor = Constants.darkTextColor
        titleLabel.textAlignment = .center
        contentView.addSubview(titleLabel)
    }

    private func configureCollectionView() {
        imageCollectionView.translatesAutoresizingMaskIntoConstraints = false
        imageCollectionView.backgroundColor = .clear
        imageCollectionView.showsHorizontalScrollIndicator = false
        imageCollectionView.decelerationRate = .fast
        imageCollectionView.contentInset = UIEdgeInsets(top: 0, left: Constants.horizontalInset, bottom: 0, right: Constants.horizontalInset)
        imageCollectionView.dataSource = self
        imageCollectionView.delegate = self
        imageCollectionView.register(ActivityDetailImageCell.self, forCellWithReuseIdentifier: ActivityDetailImageCell.reuseIdentifier)
        contentView.addSubview(imageCollectionView)
    }

    private func configureInfoCard() {
        infoCardView.translatesAutoresizingMaskIntoConstraints = false
        infoCardView.backgroundColor = .white
        infoCardView.layer.cornerRadius = 14

        activityTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        activityTitleLabel.font = AppFont.bold(size: 17)
        activityTitleLabel.textColor = Constants.darkTextColor

        dateLabel.translatesAutoresizingMaskIntoConstraints = false
        dateLabel.font = AppFont.medium(size: 10)
        dateLabel.textColor = Constants.darkTextColor

        locationIconView.translatesAutoresizingMaskIntoConstraints = false
        locationIconView.image = UIImage(named: "location")
        locationIconView.contentMode = .scaleAspectFit

        locationLabel.translatesAutoresizingMaskIntoConstraints = false
        locationLabel.font = AppFont.semibold(size: 10)
        locationLabel.textColor = Constants.darkTextColor

        joinButton.translatesAutoresizingMaskIntoConstraints = false
        joinButton.setTitle(NSLocalizedString("+ Join", comment: "Join activity button"), for: .normal)
        joinButton.setTitleColor(.white, for: .normal)
        joinButton.titleLabel?.font = AppFont.bold(size: 15)
        joinButton.backgroundColor = Constants.burgundyColor
        joinButton.layer.cornerRadius = 24
        joinButton.addTarget(self, action: #selector(handleJoinTapped), for: .touchUpInside)

        participatedLabel.translatesAutoresizingMaskIntoConstraints = false
        participatedLabel.text = NSLocalizedString("Participated", comment: "Activity participated tag")
        participatedLabel.backgroundColor = Constants.burgundyColor
        participatedLabel.textColor = .white
        participatedLabel.font = AppFont.bold(size: 14)
        participatedLabel.textAlignment = .center
        participatedLabel.layer.masksToBounds = true
        participatedLabel.layer.cornerRadius = 24
        participatedLabel.isHidden = true

        contentView.addSubview(infoCardView)
        infoCardView.addSubview(activityTitleLabel)
        infoCardView.addSubview(dateLabel)
        infoCardView.addSubview(locationIconView)
        infoCardView.addSubview(locationLabel)
        infoCardView.addSubview(joinButton)
        infoCardView.addSubview(participatedLabel)
    }

    private func configureLayout() {
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),

            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 48),
            titleLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            titleLabel.leadingAnchor.constraint(greaterThanOrEqualTo: contentView.leadingAnchor, constant: 72),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor, constant: -72),

            imageCollectionView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 24),
            imageCollectionView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageCollectionView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            imageCollectionView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.56),

            infoCardView.topAnchor.constraint(equalTo: imageCollectionView.bottomAnchor, constant: 24),
            infoCardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: Constants.horizontalInset),
            infoCardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -Constants.horizontalInset),
            infoCardView.heightAnchor.constraint(equalToConstant: 96),

            activityTitleLabel.topAnchor.constraint(equalTo: infoCardView.topAnchor, constant: 18),
            activityTitleLabel.leadingAnchor.constraint(equalTo: infoCardView.leadingAnchor, constant: 18),
            activityTitleLabel.trailingAnchor.constraint(lessThanOrEqualTo: participatedLabel.leadingAnchor, constant: -12),

            dateLabel.topAnchor.constraint(equalTo: activityTitleLabel.bottomAnchor, constant: 10),
            dateLabel.leadingAnchor.constraint(equalTo: activityTitleLabel.leadingAnchor),
            dateLabel.trailingAnchor.constraint(lessThanOrEqualTo: participatedLabel.leadingAnchor, constant: -12),

            locationIconView.leadingAnchor.constraint(equalTo: activityTitleLabel.leadingAnchor),
            locationIconView.bottomAnchor.constraint(equalTo: infoCardView.bottomAnchor, constant: -17),
            locationIconView.widthAnchor.constraint(equalToConstant: 13),
            locationIconView.heightAnchor.constraint(equalToConstant: 13),

            locationLabel.leadingAnchor.constraint(equalTo: locationIconView.trailingAnchor, constant: 5),
            locationLabel.centerYAnchor.constraint(equalTo: locationIconView.centerYAnchor),
            locationLabel.trailingAnchor.constraint(lessThanOrEqualTo: participatedLabel.leadingAnchor, constant: -12),

            joinButton.trailingAnchor.constraint(equalTo: infoCardView.trailingAnchor, constant: -14),
            joinButton.bottomAnchor.constraint(equalTo: infoCardView.bottomAnchor, constant: 22),
            joinButton.widthAnchor.constraint(equalToConstant: 88),
            joinButton.heightAnchor.constraint(equalToConstant: 48),

            participatedLabel.trailingAnchor.constraint(equalTo: joinButton.trailingAnchor),
            participatedLabel.bottomAnchor.constraint(equalTo: joinButton.bottomAnchor),
            participatedLabel.widthAnchor.constraint(equalToConstant: 112),
            participatedLabel.heightAnchor.constraint(equalTo: joinButton.heightAnchor),

            contentView.bottomAnchor.constraint(equalTo: joinButton.bottomAnchor, constant: 52)
        ])
    }

    private func applyActivity() {
        if let displayData {
            activityTitleLabel.text = displayData.title
            dateLabel.text = displayData.dateText
            locationLabel.text = displayData.locationText
            images = makeImages(from: displayData)
            imageCollectionView.reloadData()
            updateParticipationState()
            return
        }

        activityTitleLabel.text = activity?.title ?? NSLocalizedString("Yonsei Spring Festival", comment: "Fallback activity title")
        dateLabel.text = makeDateText()
        locationLabel.text = activity?.addressText ?? NSLocalizedString("Yonsei Main Campus", comment: "Fallback activity location")
        images = makeImages()
        imageCollectionView.reloadData()
        updateParticipationState()
    }

    private func updateParticipationState() {
        guard let activity, let currentUser = loadCurrentUser() else {
            showJoinState()
            return
        }

        guard case .success(let participants) = activityRepository.fetchParticipants(for: activity) else {
            showJoinState()
            return
        }

        if participants.contains(where: { $0.user?.id == currentUser.id }) {
            showParticipatedState()
        } else {
            showJoinState()
        }
    }

    @objc private func handleJoinTapped() {
        guard let activity, let currentUser = loadCurrentUser() else {
            AppToast.show(message: NSLocalizedString("Failed to join activity", comment: "Join activity failed toast"), in: view)
            return
        }

        switch activityRepository.join(activity: activity, user: currentUser) {
        case .success:
            showParticipatedState()
            NotificationCenter.default.post(name: .activityDidPublish, object: nil)
            AppToast.show(message: NSLocalizedString("Joined activity successfully", comment: "Join activity success toast"), in: view)
        case .failure(.duplicateParticipant):
            showParticipatedState()
            AppToast.show(message: NSLocalizedString("Already participated in this activity", comment: "Join activity duplicate toast"), in: view)
        case .failure:
            AppToast.show(message: NSLocalizedString("Failed to join activity", comment: "Join activity failed toast"), in: view)
        }
    }

    private func showJoinState() {
        joinButton.isHidden = false
        participatedLabel.isHidden = true
    }

    private func showParticipatedState() {
        joinButton.isHidden = true
        participatedLabel.isHidden = false
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

    private func makeDateText() -> String {
        guard let startAt = activity?.startAt else {
            return NSLocalizedString("May 24 | Fri 10:00 AM", comment: "Fallback activity date")
        }

        let formatter = DateFormatter()
        formatter.locale = .current
        formatter.dateFormat = "MMM d | E h:mm a"
        return formatter.string(from: startAt)
    }

    private func makeImages() -> [UIImage] {
        guard let activity,
              case .success(let activityImages) = activityRepository.fetchImages(for: activity) else {
            return ["build", "build_sel", "photo"].compactMap { UIImage(named: $0) }
        }

        let loadedImages = activityImages.compactMap { image in
            UIImage.sandboxOrAssetImage(named: image.localPath, documentsSubdirectory: "ActivityImages")
        }
        return loadedImages.isEmpty ? ["build", "build_sel", "photo"].compactMap { UIImage(named: $0) } : loadedImages
    }

    private func makeImages(from displayData: ActivityDetailData) -> [UIImage] {
        let pathImages = displayData.imagePaths.compactMap {
            UIImage.sandboxOrAssetImage(named: $0, documentsSubdirectory: "ActivityImages")
        }
        let assetImages = pathImages.isEmpty ? displayData.imageNames.compactMap { UIImage(named: $0) } : []
        let loadedImages = pathImages + assetImages
        return loadedImages.isEmpty ? ["build", "build_sel", "photo"].compactMap { UIImage(named: $0) } : loadedImages
    }
}

extension ActivityDetailViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        images.count
    }

    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: ActivityDetailImageCell.reuseIdentifier,
            for: indexPath
        ) as? ActivityDetailImageCell else {
            return UICollectionViewCell()
        }

        cell.configure(image: images[indexPath.item])
        return cell
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        CGSize(width: collectionView.bounds.width * 0.56, height: collectionView.bounds.height)
    }
}

private final class ActivityDetailImageCell: UICollectionViewCell {
    static let reuseIdentifier = "ActivityDetailImageCell"

    private let imageView = UIImageView()

    override init(frame: CGRect) {
        super.init(frame: frame)

        configure()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }

    func configure(image: UIImage) {
        imageView.image = image
    }

    private func configure() {
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 16
        contentView.addSubview(imageView)

        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
    }
}
