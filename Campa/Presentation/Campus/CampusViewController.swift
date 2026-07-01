import UIKit

final class CampusViewController: BaseViewController {
    fileprivate enum Constants {
        static let backgroundColor = UIColor(red: 0.98, green: 0.93, blue: 0.86, alpha: 1.0)
        static let purpleColor = UIColor(red: 0.72, green: 0.62, blue: 0.97, alpha: 1.0)
        static let limeColor = UIColor(red: 0.86, green: 0.90, blue: 0.12, alpha: 1.0)
        static let darkTextColor = UIColor(red: 52/255.0, green: 4/255, blue: 4/255.0, alpha: 1.0)
        static let horizontalInset: CGFloat = 24
        static let recentHeaderHeight: CGFloat = 44
    }

    private let titleLabel = UILabel()
    private let locationIconView = UIImageView()
    private let locationLabel = UILabel()
    private let starContainerView = UIImageView()
    private let recentHeaderView = UIView()
    private let recentIconView = UIImageView()
    private let recentTitleLabel = UILabel()
    private let recentAddButton = UIButton(type: .custom)
    private let tableView = UITableView(frame: .zero, style: .plain)
    private let activityRepository: ActivityRepository
    private let userRepository: UserRepository

    private var activities: [CampusActivity] = []

    init(activityRepository: ActivityRepository = ActivityRepository(), userRepository: UserRepository = UserRepository()) {
        self.activityRepository = activityRepository
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
        configureHeader()
        configureRecentHeader()
        configureTableView()
        configureLayout()
        configureNotification()
        updateCurrentCity()
        loadActivities()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    private func configureView() {
        view.backgroundColor = Constants.backgroundColor
        navBar.backgroundColor = .clear
    }

    private func configureHeader() {
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = NSLocalizedString("Campus", comment: "Campus screen title")
        titleLabel.font = AppFont.bold(size: 20)
        titleLabel.textColor = Constants.darkTextColor

        locationIconView.translatesAutoresizingMaskIntoConstraints = false
        locationIconView.image = UIImage(named: "location")
        locationIconView.contentMode = .scaleAspectFit

        locationLabel.translatesAutoresizingMaskIntoConstraints = false
        locationLabel.text = NSLocalizedString("Current City", comment: "Current city placeholder")
        locationLabel.font = AppFont.medium(size: 10)
        locationLabel.textColor = Constants.darkTextColor

        starContainerView.translatesAutoresizingMaskIntoConstraints = false
        starContainerView.backgroundColor = .clear
        starContainerView.layer.borderColor = UIColor(red: 0.45, green: 0.36, blue: 0.30, alpha: 0.45).cgColor
        starContainerView.image = UIImage(named: "star")
        starContainerView.contentMode = .scaleAspectFill

        view.addSubview(titleLabel)
        view.addSubview(locationIconView)
        view.addSubview(locationLabel)
        view.addSubview(starContainerView)
    }

    private func configureRecentHeader() {
        recentHeaderView.translatesAutoresizingMaskIntoConstraints = false
        recentHeaderView.backgroundColor = .clear

        recentIconView.translatesAutoresizingMaskIntoConstraints = false
        recentIconView.image = UIImage(named: "camp")
        recentIconView.contentMode = .scaleAspectFit

        recentTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        recentTitleLabel.text = NSLocalizedString("Recent Activities", comment: "Recent activities header title")
        recentTitleLabel.font = AppFont.medium(size: 14)
        recentTitleLabel.textColor = Constants.darkTextColor

        recentAddButton.translatesAutoresizingMaskIntoConstraints = false
        recentAddButton.setTitle("+", for: .normal)
        recentAddButton.setTitleColor(Constants.darkTextColor, for: .normal)
        recentAddButton.titleLabel?.font = AppFont.bold(size: 30)
        recentAddButton.addTarget(self, action: #selector(handleRecentAddTapped), for: .touchUpInside)

        recentHeaderView.addSubview(recentIconView)
        recentHeaderView.addSubview(recentTitleLabel)
        recentHeaderView.addSubview(recentAddButton)
        view.addSubview(recentHeaderView)
    }

    private func configureTableView() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.showsVerticalScrollIndicator = false
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 112
        tableView.contentInset = UIEdgeInsets(top: 8, left: 0, bottom: 120, right: 0)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(CampusActivityTableViewCell.self, forCellReuseIdentifier: CampusActivityTableViewCell.reuseIdentifier)
        view.addSubview(tableView)
    }

    private func configureLayout() {
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 7),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: Constants.horizontalInset),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: starContainerView.leadingAnchor, constant: -16),

            locationIconView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            locationIconView.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            locationIconView.widthAnchor.constraint(equalToConstant: 12),
            locationIconView.heightAnchor.constraint(equalToConstant: 12),

            locationLabel.leadingAnchor.constraint(equalTo: locationIconView.trailingAnchor, constant: 5),
            locationLabel.centerYAnchor.constraint(equalTo: locationIconView.centerYAnchor),
            locationLabel.trailingAnchor.constraint(lessThanOrEqualTo: starContainerView.leadingAnchor, constant: -16),

            starContainerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 7),
            starContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            starContainerView.widthAnchor.constraint(equalToConstant: 88),
            starContainerView.heightAnchor.constraint(equalToConstant: 29),

            recentHeaderView.topAnchor.constraint(equalTo: locationIconView.bottomAnchor, constant: 22),
            recentHeaderView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: Constants.horizontalInset),
            recentHeaderView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -Constants.horizontalInset),
            recentHeaderView.heightAnchor.constraint(equalToConstant: Constants.recentHeaderHeight),

            recentIconView.leadingAnchor.constraint(equalTo: recentHeaderView.leadingAnchor),
            recentIconView.centerYAnchor.constraint(equalTo: recentHeaderView.centerYAnchor),
            recentIconView.widthAnchor.constraint(equalToConstant: 30),
            recentIconView.heightAnchor.constraint(equalToConstant: 30),

            recentTitleLabel.leadingAnchor.constraint(equalTo: recentIconView.trailingAnchor, constant: 8),
            recentTitleLabel.centerYAnchor.constraint(equalTo: recentHeaderView.centerYAnchor),
            recentTitleLabel.trailingAnchor.constraint(lessThanOrEqualTo: recentAddButton.leadingAnchor, constant: -12),

            recentAddButton.trailingAnchor.constraint(equalTo: recentHeaderView.trailingAnchor),
            recentAddButton.centerYAnchor.constraint(equalTo: recentHeaderView.centerYAnchor),
            recentAddButton.widthAnchor.constraint(equalToConstant: 44),
            recentAddButton.heightAnchor.constraint(equalToConstant: 44),

            tableView.topAnchor.constraint(equalTo: recentHeaderView.bottomAnchor, constant: 6),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    @objc private func handleRecentAddTapped() {
        let vc = ActivityCreateViewController()
        vc.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(vc, animated: true)
    }

    private func configureNotification() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleActivityDidPublish),
            name: .activityDidPublish,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleUserBlockRelationDidChange),
            name: .userBlockRelationDidChange,
            object: nil
        )
    }

    @objc private func handleActivityDidPublish() {
        loadActivities()
    }

    @objc private func handleUserBlockRelationDidChange() {
        loadActivities()
    }

    private func updateCurrentCity() {
        CurrentCityProvider.shared.requestCurrentCity { [weak self] city in
            guard let self, let city else { return }
            DispatchQueue.main.async {
                self.locationLabel.text = city
            }
        }
    }

    private func loadActivities() {
        guard case .success(let databaseActivities) = activityRepository.fetchPublishedActivities() else {
            activities = []
            tableView.reloadData()
            return
        }

        let visibleActivities = filterBlockedActivities(databaseActivities)
        AppLoading.show(in: self.view) { [weak self] in
            guard let self = self else { return }
            activities = visibleActivities.map(makeCampusActivity)
            self.tableView.reloadData()
        }
    }

    private func filterBlockedActivities(_ activities: [Activity]) -> [Activity] {
        guard let currentUser = loadCurrentUser(),
              case .success(let blockedUsers) = userRepository.fetchBlockedUsers(for: currentUser),
              !blockedUsers.isEmpty else {
            return activities
        }

        let blockedUserIds = Set(blockedUsers.map(\.id))
        return activities.filter { activity in
            guard let authorId = activity.author?.id else {
                return true
            }
            return !blockedUserIds.contains(authorId)
        }
    }

    private func makeCampusActivity(from activity: Activity) -> CampusActivity {
        let images = (try? activityRepository.fetchImages(for: activity).get()) ?? []
        let imagePaths = images.prefix(3).map(\.localPath)
        return CampusActivity(
            activity: activity,
            imageNames: ["build", "build_sel", "photo"],
            imagePaths: imagePaths,
            title: activity.title,
            date: makeDateText(from: activity.startAt),
            campus: activity.addressText ?? NSLocalizedString("Yonsei Main Campus", comment: "Default activity campus"),
            isParticipated: isActivityParticipated(activity)
        )
    }

    private func isActivityParticipated(_ activity: Activity) -> Bool {
        guard let currentUser = loadCurrentUser(),
              case .success(let participants) = activityRepository.fetchParticipants(for: activity) else {
            return false
        }

        return participants.contains { $0.user?.id == currentUser.id }
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

    private func makeDateText(from date: Date?) -> String {
        guard let date else {
            return NSLocalizedString("No time", comment: "Activity empty time")
        }

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "MMM d | E h:mm a"
        return formatter.string(from: date)
    }
    private func showActivityDetail(for activity: CampusActivity) {
        let detailData = ActivityDetailData(
            title: activity.title,
            dateText: activity.date,
            locationText: activity.campus,
            imageNames: activity.imageNames,
            imagePaths: activity.imagePaths
        )
        let viewController = ActivityDetailViewController(activity: activity.activity, displayData: detailData)
        viewController.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(viewController, animated: true)
    }
}

extension CampusViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        activities.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: CampusActivityTableViewCell.reuseIdentifier,
            for: indexPath
        ) as? CampusActivityTableViewCell else {
            return UITableViewCell()
        }

        cell.configure(activity: activities[indexPath.row])
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard activities.indices.contains(indexPath.row) else { return }
        showActivityDetail(for: activities[indexPath.row])
    }
}

private struct CampusActivity {
    var activity: Activity? = nil
    let imageNames: [String]
    var imagePaths: [String] = []
    let title: String
    let date: String
    let campus: String
    let isParticipated: Bool
}

private final class CampusActivityTableViewCell: UITableViewCell {
    static let reuseIdentifier = "CampusActivityTableViewCell"

    private let cardView = UIView()
    private let activityImageView = UIImageView()
    private let titleLabel = UILabel()
    private let dateLabel = UILabel()
    private let locationIconView = UIImageView()
    private let campusLabel = UILabel()
    private let joinButton = UIButton(type: .system)

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        configureViews()
        configureLayout()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }

    func configure(activity: CampusActivity) {
        activityImageView.image = makeActivityImage(from: activity.imagePaths.first) ?? UIImage(named: activity.imageNames.first ?? "build")
        titleLabel.text = activity.title
        dateLabel.text = activity.date
        campusLabel.text = activity.campus
        let buttonTitle = activity.isParticipated
            ? NSLocalizedString("Participated", comment: "Campus activity participated button")
            : NSLocalizedString("+ Join", comment: "Join campus activity button")
        joinButton.setTitle(buttonTitle, for: .normal)
    }

    private func makeActivityImage(from imagePath: String?) -> UIImage? {
        UIImage.sandboxOrAssetImage(named: imagePath, documentsSubdirectory: "ActivityImages")
    }

    private func configureViews() {
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        selectionStyle = .none

        cardView.translatesAutoresizingMaskIntoConstraints = false
        cardView.backgroundColor = CampusViewController.Constants.purpleColor
        cardView.layer.cornerRadius = 14
        cardView.clipsToBounds = true

        activityImageView.translatesAutoresizingMaskIntoConstraints = false
        activityImageView.contentMode = .scaleAspectFill
        activityImageView.layer.cornerRadius = 10
        activityImageView.clipsToBounds = true

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = AppFont.bold(size: 13)
        titleLabel.textColor = .white

        dateLabel.translatesAutoresizingMaskIntoConstraints = false
        dateLabel.font = AppFont.medium(size: 9)
        dateLabel.textColor = UIColor.white.withAlphaComponent(0.82)

        locationIconView.translatesAutoresizingMaskIntoConstraints = false
        locationIconView.image = UIImage(named: "local_icon")
        locationIconView.contentMode = .scaleAspectFit

        campusLabel.translatesAutoresizingMaskIntoConstraints = false
        campusLabel.font = AppFont.medium(size: 9)
        campusLabel.textColor = UIColor.white.withAlphaComponent(0.86)

        joinButton.translatesAutoresizingMaskIntoConstraints = false
        joinButton.setTitle(NSLocalizedString("+ Join", comment: "Join campus activity button"), for: .normal)
        joinButton.setTitleColor(UIColor.white, for: .normal)
        joinButton.titleLabel?.font = AppFont.bold(size: 12)
        joinButton.backgroundColor = CampusViewController.Constants.limeColor
        joinButton.layer.cornerRadius = 15
        joinButton.contentEdgeInsets = UIEdgeInsets(top: 0, left: 12, bottom: 0, right: 12)
        joinButton.setContentHuggingPriority(.required, for: .horizontal)
        joinButton.isUserInteractionEnabled = false
        
        contentView.addSubview(cardView)
        cardView.addSubview(activityImageView)
        cardView.addSubview(titleLabel)
        cardView.addSubview(dateLabel)
        cardView.addSubview(locationIconView)
        cardView.addSubview(campusLabel)
        cardView.addSubview(joinButton)
    }

    private func configureLayout() {
        NSLayoutConstraint.activate([
            cardView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6),
            cardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: CampusViewController.Constants.horizontalInset),
            cardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -CampusViewController.Constants.horizontalInset),
            cardView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            cardView.heightAnchor.constraint(equalToConstant: 100),

            activityImageView.topAnchor.constraint(equalTo: cardView.topAnchor),
            activityImageView.leadingAnchor.constraint(equalTo: cardView.leadingAnchor),
            activityImageView.bottomAnchor.constraint(equalTo: cardView.bottomAnchor),
            activityImageView.widthAnchor.constraint(equalToConstant: 94),

            titleLabel.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: activityImageView.trailingAnchor, constant: 14),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: cardView.trailingAnchor, constant: -14),

            dateLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            dateLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            dateLabel.trailingAnchor.constraint(lessThanOrEqualTo: cardView.trailingAnchor, constant: -14),

            locationIconView.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            locationIconView.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -17),
            locationIconView.widthAnchor.constraint(equalToConstant: 11),
            locationIconView.heightAnchor.constraint(equalToConstant: 11),

            campusLabel.leadingAnchor.constraint(equalTo: locationIconView.trailingAnchor, constant: 5),
            campusLabel.centerYAnchor.constraint(equalTo: locationIconView.centerYAnchor),
            campusLabel.trailingAnchor.constraint(lessThanOrEqualTo: joinButton.leadingAnchor, constant: -10),

            joinButton.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -10),
            joinButton.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -12),
            joinButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 62),
            joinButton.heightAnchor.constraint(equalToConstant: 30)
        ])
    }
}
