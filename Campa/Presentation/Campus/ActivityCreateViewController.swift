import UIKit

final class ActivityCreateViewController: BaseViewController {
    private enum Constants {
        static let backgroundColor = UIColor(red: 0.98, green: 0.93, blue: 0.86, alpha: 1.0)
        static let purpleColor = UIColor(red: 0.72, green: 0.62, blue: 0.97, alpha: 1.0)
        static let darkTextColor = UIColor(red: 0.28, green: 0.02, blue: 0.02, alpha: 1.0)
        static let horizontalInset: CGFloat = 24
    }

    private let contentCardView = UIView()
    private let themeTextField = UITextField()
    private let dateTextField = UITextField()
    private let datePicker = UIDatePicker()
    private let collectionView: UICollectionView
    private let locationIconView = UIImageView()
    private let locationLabel = UILabel()
    private let publishButton = UIButton(type: .system)
    private let userRepository: UserRepository
    private let activityRepository: ActivityRepository

    private var selectedImages: [UIImage] = []
    private var selectedDate = Calendar.current.date(from: DateComponents(year: 2026, month: 5, day: 24, hour: 10))
    private var collectionHeight: CGFloat = 0

    init(userRepository: UserRepository = UserRepository(), activityRepository: ActivityRepository = ActivityRepository()) {
        self.userRepository = userRepository
        self.activityRepository = activityRepository

        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = 12
        layout.minimumInteritemSpacing = 12
        let collectionHorizontalInset = Constants.horizontalInset * 2 + 24
        let itemSpacing = layout.minimumInteritemSpacing * 2
        let itemWidth = floor((UIScreen.main.bounds.width - collectionHorizontalInset - itemSpacing) / 3)
        layout.itemSize = CGSize(width: itemWidth, height: itemWidth * 1.4)
        collectionHeight = itemWidth * 1.4
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)

        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        configureNavigation()
        configureContentCard()
        configureFields()
        configureCollectionView()
        configureLocation()
        loadCurrentUserLocation()
        configurePublishButton()
        configureLayout()
    }

    private func configureNavigation() {
        view.backgroundColor = Constants.backgroundColor
        navBar.backgroundColor = .clear
        changeNavbar(.backTiltle)
        self.setTitleAndRight(title: "Activitie", right: nil)
    }

    private func configureContentCard() {
        contentCardView.translatesAutoresizingMaskIntoConstraints = false
        contentCardView.backgroundColor = Constants.purpleColor
        contentCardView.layer.cornerRadius = 16
        contentCardView.clipsToBounds = true
        view.addSubview(contentCardView)
    }

    private func configureFields() {
        configureTextField(themeTextField, placeholder: NSLocalizedString("Please enter the event theme.", comment: "Activity theme placeholder"))
        configureTextField(dateTextField, placeholder: "")
        dateTextField.text = makeDateText(from: selectedDate)

        datePicker.datePickerMode = .dateAndTime
        datePicker.preferredDatePickerStyle = .wheels
        if let selectedDate {
            datePicker.date = selectedDate
        }
        datePicker.addTarget(self, action: #selector(handleDateChanged), for: .valueChanged)
        dateTextField.inputView = datePicker

        let downIconView = UIImageView(image: UIImage(named: "down_p"))
        downIconView.contentMode = .scaleAspectFit
        downIconView.frame = CGRect(x: 10, y: 4, width: 14, height: 10)
        let downIconContainerView = UIView(frame: CGRect(x: 0, y: 0, width: 34, height: 18))
        downIconContainerView.addSubview(downIconView)
        downIconContainerView.isUserInteractionEnabled = true
        downIconContainerView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleDateIconTapped)))
        dateTextField.rightView = downIconContainerView
        dateTextField.rightViewMode = .always

        contentCardView.addSubview(themeTextField)
        contentCardView.addSubview(dateTextField)
    }

    private func configureTextField(_ textField: UITextField, placeholder: String) {
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.backgroundColor = .white
        textField.layer.cornerRadius = 12
        textField.clipsToBounds = true
        textField.font = AppFont.medium(size: 12)
        textField.textColor = Constants.darkTextColor
        textField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 14, height: 1))
        textField.leftViewMode = .always
        textField.attributedPlaceholder = NSAttributedString(
            string: placeholder,
            attributes: [
                .foregroundColor: UIColor(red: 0.68, green: 0.62, blue: 0.58, alpha: 1.0),
                .font: AppFont.medium(size: 10)
            ]
        )
    }

    private func configureCollectionView() {
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.backgroundColor = .clear
        collectionView.showsVerticalScrollIndicator = false
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(ActivityImageCollectionViewCell.self, forCellWithReuseIdentifier: ActivityImageCollectionViewCell.reuseIdentifier)
        contentCardView.addSubview(collectionView)
    }

    private func configureLocation() {
        locationIconView.translatesAutoresizingMaskIntoConstraints = false
        locationIconView.image = UIImage(named: "location")
        locationIconView.contentMode = .scaleAspectFit
        locationIconView.tintColor = Constants.darkTextColor

        locationLabel.translatesAutoresizingMaskIntoConstraints = false
        locationLabel.text = NSLocalizedString("Current City", comment: "Current city placeholder")
        locationLabel.font = AppFont.medium(size: 11)
        locationLabel.textColor = Constants.darkTextColor

        contentCardView.addSubview(locationIconView)
        contentCardView.addSubview(locationLabel)
    }

    private func loadCurrentUserLocation() {
        CurrentCityProvider.shared.requestCurrentCity { [weak self] city in
            guard let self, let city else { return }
            DispatchQueue.main.async {
                self.locationLabel.text = city
            }
        }
    }

    private func configurePublishButton() {
        publishButton.translatesAutoresizingMaskIntoConstraints = false
        publishButton.setTitle(NSLocalizedString("Publish", comment: "Publish activity button title"), for: .normal)
        publishButton.setTitleColor(.white, for: .normal)
        publishButton.titleLabel?.font = AppFont.medium(size: 16)
        publishButton.backgroundColor = Constants.darkTextColor
        publishButton.layer.cornerRadius = 22
        publishButton.addTarget(self, action: #selector(handlePublishTapped), for: .touchUpInside)
        view.addSubview(publishButton)
    }

    private func configureLayout() {
        NSLayoutConstraint.activate([
            contentCardView.topAnchor.constraint(equalTo: navBar.bottomAnchor, constant: 10),
            contentCardView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: Constants.horizontalInset),
            contentCardView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -Constants.horizontalInset),
            contentCardView.heightAnchor.constraint(equalToConstant: 360),

            themeTextField.topAnchor.constraint(equalTo: contentCardView.topAnchor, constant: 14),
            themeTextField.leadingAnchor.constraint(equalTo: contentCardView.leadingAnchor, constant: 12),
            themeTextField.trailingAnchor.constraint(equalTo: contentCardView.trailingAnchor, constant: -12),
            themeTextField.heightAnchor.constraint(equalToConstant: 54),

            dateTextField.topAnchor.constraint(equalTo: themeTextField.bottomAnchor, constant: 14),
            dateTextField.leadingAnchor.constraint(equalTo: themeTextField.leadingAnchor),
            dateTextField.trailingAnchor.constraint(equalTo: themeTextField.trailingAnchor),
            dateTextField.heightAnchor.constraint(equalToConstant: 54),

            collectionView.topAnchor.constraint(equalTo: dateTextField.bottomAnchor, constant: 18),
            collectionView.leadingAnchor.constraint(equalTo: themeTextField.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: themeTextField.trailingAnchor),
            collectionView.heightAnchor.constraint(equalToConstant: collectionHeight),

            locationIconView.topAnchor.constraint(equalTo: collectionView.bottomAnchor, constant: 16),
            locationIconView.leadingAnchor.constraint(equalTo: themeTextField.leadingAnchor),
            locationIconView.widthAnchor.constraint(equalToConstant: 18),
            locationIconView.heightAnchor.constraint(equalToConstant: 18),

            locationLabel.leadingAnchor.constraint(equalTo: locationIconView.trailingAnchor, constant: 6),
            locationLabel.centerYAnchor.constraint(equalTo: locationIconView.centerYAnchor),
            locationLabel.trailingAnchor.constraint(lessThanOrEqualTo: contentCardView.trailingAnchor, constant: -12),

            publishButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 78),
            publishButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -78),
            publishButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -44),
            publishButton.heightAnchor.constraint(equalToConstant: 44)
        ])
    }

    @objc private func handleDateChanged() {
        selectedDate = datePicker.date
        dateTextField.text = makeDateText(from: selectedDate)
    }

    @objc private func handleDateIconTapped() {
        dateTextField.becomeFirstResponder()
    }

    @objc private func handlePublishTapped() {
        let title = themeTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let addressText = locationLabel.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        guard let userIdString = UserDefaults.standard.string(forKey: CurrentUserIdKey),
              let userId = UUID(uuidString: userIdString),
              case .success(let currentUser) = userRepository.fetchUser(id: userId) else {
            showToast(message: NSLocalizedString("Failed to publish activity", comment: "Activity publish failed toast"))
            return
        }

        guard !isGuestUser(currentUser) else {
            showLoginAlert()
            return
        }

        guard !title.isEmpty, !addressText.isEmpty else {
            showToast(message: NSLocalizedString("Please complete activity information", comment: "Activity required fields toast"))
            return
        }

        let imagePaths = selectedImages.compactMap(saveActivityImage)
        guard imagePaths.count == selectedImages.count else {
            showToast(message: NSLocalizedString("Failed to save activity images", comment: "Activity image save failed toast"))
            return
        }

        let result = activityRepository.createActivity(
            author: currentUser,
            title: title,
            content: title,
            addressText: addressText,
            startAt: selectedDate,
            endAt: nil,
            maxParticipants: 0,
            imagePaths: imagePaths
        )

        switch result {
        case .success:
            showToast(message: NSLocalizedString("Activity published", comment: "Activity publish success toast"))
            NotificationCenter.default.post(name: .activityDidPublish, object: nil)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { [weak self] in
                self?.navigationController?.popViewController(animated: true)
            }
        case .failure:
            showToast(message: NSLocalizedString("Failed to publish activity", comment: "Activity publish failed toast"))
        }
    }

    private func isGuestUser(_ user: User) -> Bool {
        if let guestUserId = UserDefaults.standard.string(forKey: GuestUserIdKey),
           guestUserId == user.id.uuidString {
            return true
        }

        return user.email?.lowercased().hasSuffix("@guest.campa") == true
    }

    private func showLoginAlert() {
        guard presentedViewController == nil else {
            return
        }

        present(LoginAlertController(), animated: false)
    }

    private func makeDateText(from date: Date?) -> String {
        guard let date else {
            return ""
        }

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "MMM d (E) h:mm a"
        return formatter.string(from: date)
    }

    private func saveActivityImage(_ image: UIImage) -> String? {
        guard let imageData = image.jpegData(compressionQuality: 0.88),
              let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }

        let activitiesDirectoryURL = documentsURL.appendingPathComponent("ActivityImages", isDirectory: true)
        do {
            try FileManager.default.createDirectory(at: activitiesDirectoryURL, withIntermediateDirectories: true)
            let imageName = "\(UUID().uuidString).jpg"
            let fileURL = activitiesDirectoryURL.appendingPathComponent(imageName)
            try imageData.write(to: fileURL, options: .atomic)
            return imageName
        } catch {
            return nil
        }
    }

    private func showToast(message: String) {
        AppToast.show(
            message: message,
            in: view,
            relation: .above(publishButton.topAnchor, spacing: 18),
            accessibilityIdentifier: "activityCreateToastLabel"
        )
    }
}

extension ActivityCreateViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        selectedImages.count < 3 ? selectedImages.count + 1 : selectedImages.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: ActivityImageCollectionViewCell.reuseIdentifier,
            for: indexPath
        ) as? ActivityImageCollectionViewCell else {
            return UICollectionViewCell()
        }

        if selectedImages.indices.contains(indexPath.item) {
            cell.configure(image: selectedImages[indexPath.item])
            cell.onRemove = { [weak self] in
                self?.removeImage(at: indexPath.item)
            }
        } else {
            cell.configureAdd()
            cell.onRemove = nil
        }
        return cell
    }
}

extension ActivityCreateViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard indexPath.item == selectedImages.count, selectedImages.count < 3 else {
            return
        }
        presentPhotoPicker()
    }

    private func presentPhotoPicker() {
        guard UIImagePickerController.isSourceTypeAvailable(.photoLibrary) else {
            return
        }

        let picker = UIImagePickerController()
        picker.sourceType = .photoLibrary
        picker.allowsEditing = false
        picker.delegate = self
        present(picker, animated: true)
    }

    private func removeImage(at index: Int) {
        guard selectedImages.indices.contains(index) else {
            return
        }

        selectedImages.remove(at: index)
        collectionView.reloadData()
    }
}

extension ActivityCreateViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(
        _ picker: UIImagePickerController,
        didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
    ) {
        if let image = info[.originalImage] as? UIImage, selectedImages.count < 3 {
            selectedImages.append(image)
            collectionView.reloadData()
        }
        picker.dismiss(animated: true)
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
}

private final class ActivityImageCollectionViewCell: UICollectionViewCell {
    static let reuseIdentifier = "ActivityImageCollectionViewCell"

    var onRemove: (() -> Void)?

    private let imageView = UIImageView()
    private let addIconView = UIImageView()
    private let removeButton = UIButton(type: .system)

    override init(frame: CGRect) {
        super.init(frame: frame)

        configureViews()
        configureLayout()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.image = nil
        addIconView.isHidden = true
        removeButton.isHidden = true
        onRemove = nil
    }

    func configure(image: UIImage) {
        imageView.image = image
        imageView.backgroundColor = .clear
        addIconView.isHidden = true
        removeButton.isHidden = false
    }

    func configureAdd() {
        imageView.image = nil
        imageView.backgroundColor = .white
        addIconView.isHidden = false
        removeButton.isHidden = true
    }

    private func configureViews() {
        contentView.backgroundColor = .clear

        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFill
        imageView.layer.cornerRadius = 10
        imageView.clipsToBounds = true

        addIconView.translatesAutoresizingMaskIntoConstraints = false
        addIconView.image = UIImage(systemName: "photo.badge.plus")
        addIconView.tintColor = UIColor(red: 0.28, green: 0.02, blue: 0.02, alpha: 1.0)
        addIconView.contentMode = .scaleAspectFit
        addIconView.isHidden = true

        removeButton.translatesAutoresizingMaskIntoConstraints = false
        removeButton.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        removeButton.tintColor = .white
        removeButton.backgroundColor = UIColor.black.withAlphaComponent(0.28)
        removeButton.layer.cornerRadius = 10
        removeButton.isHidden = true
        removeButton.addTarget(self, action: #selector(removeButtonTapped), for: .touchUpInside)

        contentView.addSubview(imageView)
        contentView.addSubview(addIconView)
        contentView.addSubview(removeButton)
    }

    private func configureLayout() {
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

            addIconView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            addIconView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            addIconView.widthAnchor.constraint(equalToConstant: 24),
            addIconView.heightAnchor.constraint(equalToConstant: 24),

            removeButton.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
            removeButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -4),
            removeButton.widthAnchor.constraint(equalToConstant: 20),
            removeButton.heightAnchor.constraint(equalToConstant: 20)
        ])
    }

    @objc private func removeButtonTapped() {
        onRemove?()
    }
}
