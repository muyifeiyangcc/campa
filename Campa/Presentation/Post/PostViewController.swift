import UIKit

final class PostViewController: BaseViewController {
    private enum Constants {
        static let backgroundColor = UIColor(red: 0.98, green: 0.93, blue: 0.86, alpha: 1.0)
        static let purpleColor = UIColor(red: 0.72, green: 0.62, blue: 0.97, alpha: 1.0)
        static let darkTextColor = UIColor(red: 0.28, green: 0.02, blue: 0.02, alpha: 1.0)
        static let horizontalInset: CGFloat = 24
        static let publishCost = 300
    }

    private let contentCardView = UIView()
    private let textView = UITextView()
    private let placeholderLabel = UILabel()
    private let collectionView: UICollectionView
    private let boostBadgeView = UIView()
    private let hotImageView = UIImageView()
    private let boostButton = UIButton(type: .custom)
    private let boostDescriptionLabel = UILabel()
    private let locationIconView = UIImageView()
    private let locationLabel = UILabel()
    private let publishButton = UIButton(type: .custom)
    private let userRepository: UserRepository
    private let postRepository: PostRepository

    private var selectedImages: [UIImage] = []
    private var collH: CGFloat = 0
    private var isBoostSelected = false {
        didSet {
            updateBoostState()
        }
    }

    init(userRepository: UserRepository = UserRepository(), postRepository: PostRepository = PostRepository()) {
        self.userRepository = userRepository
        self.postRepository = postRepository
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = 12
        layout.minimumInteritemSpacing = 12
        let collectionHorizontalInset = Constants.horizontalInset * 2 + 24
        let itemSpacing = layout.minimumInteritemSpacing * 2
        let itemWidth = floor((UIScreen.main.bounds.width - collectionHorizontalInset - itemSpacing) / 3)
        layout.itemSize = CGSize(width: itemWidth, height: itemWidth * 1.4)
        collH = itemWidth * 1.4
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
        configureTextView()
        configureCollectionView()
        configureBoostView()
        configureLocation()
        loadCurrentUserLocation()
        configurePublishButton()
        configureLayout()
    }

    private func configureNavigation() {
        changeNavbar(.backTiltle)
        self.setTitleAndRight(title: "Post", right: nil)
    }

    private func configureContentCard() {
        contentCardView.translatesAutoresizingMaskIntoConstraints = false
        contentCardView.backgroundColor = Constants.purpleColor
        contentCardView.layer.cornerRadius = 16
        contentCardView.clipsToBounds = true
        view.addSubview(contentCardView)
    }

    private func configureTextView() {
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.backgroundColor = .white
        textView.layer.cornerRadius = 10
        textView.clipsToBounds = true
        textView.font = AppFont.medium(size: 12)
        textView.textColor = Constants.darkTextColor
        textView.textContainerInset = UIEdgeInsets(top: 14, left: 12, bottom: 12, right: 12)
        textView.delegate = self

        placeholderLabel.translatesAutoresizingMaskIntoConstraints = false
        placeholderLabel.text = NSLocalizedString("Write down your feelings at this moment.", comment: "Post input placeholder")
        placeholderLabel.font = AppFont.medium(size: 10)
        placeholderLabel.textColor = UIColor(red: 0.68, green: 0.62, blue: 0.58, alpha: 1.0)

        contentCardView.addSubview(textView)
        textView.addSubview(placeholderLabel)
        updatePlaceholderVisibility()
    }

    override func backAction() {
        self.dismiss(animated: false)
    }
    
    private func configureCollectionView() {
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.backgroundColor = .clear
        collectionView.showsVerticalScrollIndicator = false
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(PostImageCollectionViewCell.self, forCellWithReuseIdentifier: PostImageCollectionViewCell.reuseIdentifier)
        contentCardView.addSubview(collectionView)
    }

    private func configureBoostView() {
        boostBadgeView.translatesAutoresizingMaskIntoConstraints = false
        boostBadgeView.layer.cornerRadius = 15

        hotImageView.translatesAutoresizingMaskIntoConstraints = false
        hotImageView.image = UIImage(named: "hot")
        hotImageView.contentMode = .scaleAspectFit

        boostButton.translatesAutoresizingMaskIntoConstraints = false
        boostButton.setTitle("x300", for: .normal)
        boostButton.setTitleColor(Constants.darkTextColor, for: .normal)
        boostButton.titleLabel?.font = AppFont.bold(size: 12)
        boostButton.backgroundColor = .clear
        boostButton.addTarget(self, action: #selector(handleBoostTapped), for: .touchUpInside)
        
        boostDescriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        boostDescriptionLabel.text = NSLocalizedString("Want to increase the visibility of your post?", comment: "Post boost description")
        boostDescriptionLabel.font = AppFont.medium(size: 9)
        boostDescriptionLabel.textColor = Constants.darkTextColor

        boostBadgeView.addSubview(hotImageView)
        boostBadgeView.addSubview(boostButton)
        contentCardView.addSubview(boostBadgeView)
        contentCardView.addSubview(boostDescriptionLabel)
        updateBoostState()
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

        view.addSubview(locationIconView)
        view.addSubview(locationLabel)
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
        publishButton.setTitle(NSLocalizedString("Publish", comment: "Publish button title"), for: .normal)
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
            contentCardView.heightAnchor.constraint(equalToConstant: 498),

            textView.topAnchor.constraint(equalTo: contentCardView.topAnchor, constant: 12),
            textView.leadingAnchor.constraint(equalTo: contentCardView.leadingAnchor, constant: 12),
            textView.trailingAnchor.constraint(equalTo: contentCardView.trailingAnchor, constant: -12),
            textView.heightAnchor.constraint(equalToConstant: 134),

            placeholderLabel.topAnchor.constraint(equalTo: textView.topAnchor, constant: 16),
            placeholderLabel.leadingAnchor.constraint(equalTo: textView.leadingAnchor, constant: 16),
            placeholderLabel.trailingAnchor.constraint(lessThanOrEqualTo: textView.trailingAnchor, constant: -16),

            collectionView.topAnchor.constraint(equalTo: textView.bottomAnchor, constant: 20),
            collectionView.leadingAnchor.constraint(equalTo: textView.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: textView.trailingAnchor),
            collectionView.heightAnchor.constraint(equalToConstant: self.collH),

            boostBadgeView.topAnchor.constraint(equalTo: collectionView.bottomAnchor, constant: 36),
            boostBadgeView.leadingAnchor.constraint(equalTo: textView.leadingAnchor),
            boostBadgeView.widthAnchor.constraint(equalToConstant: 82),
            boostBadgeView.heightAnchor.constraint(equalToConstant: 30),

            hotImageView.trailingAnchor.constraint(equalTo: boostBadgeView.trailingAnchor, constant: 3),
            hotImageView.bottomAnchor.constraint(equalTo: boostBadgeView.topAnchor, constant: 20),
            hotImageView.widthAnchor.constraint(equalToConstant: 43),
            hotImageView.heightAnchor.constraint(equalToConstant: 43),

            boostButton.topAnchor.constraint(equalTo: boostBadgeView.topAnchor),
            boostButton.leadingAnchor.constraint(equalTo: boostBadgeView.leadingAnchor),
            boostButton.trailingAnchor.constraint(equalTo: boostBadgeView.trailingAnchor),
            boostButton.bottomAnchor.constraint(equalTo: boostBadgeView.bottomAnchor),

            boostDescriptionLabel.topAnchor.constraint(equalTo: boostBadgeView.bottomAnchor, constant: 10),
            boostDescriptionLabel.leadingAnchor.constraint(equalTo: textView.leadingAnchor),
            boostDescriptionLabel.trailingAnchor.constraint(lessThanOrEqualTo: textView.trailingAnchor),

            locationIconView.topAnchor.constraint(equalTo: contentCardView.bottomAnchor, constant: 22),
            locationIconView.leadingAnchor.constraint(equalTo: contentCardView.leadingAnchor),
            locationIconView.widthAnchor.constraint(equalToConstant: 18),
            locationIconView.heightAnchor.constraint(equalToConstant: 18),

            locationLabel.leadingAnchor.constraint(equalTo: locationIconView.trailingAnchor, constant: 6),
            locationLabel.centerYAnchor.constraint(equalTo: locationIconView.centerYAnchor),
            locationLabel.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -Constants.horizontalInset),

            publishButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 78),
            publishButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -78),
            publishButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -44),
            publishButton.heightAnchor.constraint(equalToConstant: 44)
        ])
    }

    @objc private func handlePublishTapped() {
        let content = textView.text.trimmingCharacters(in: .whitespacesAndNewlines)
        let addressText = locationLabel.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        guard let userIdString = UserDefaults.standard.string(forKey: CurrentUserIdKey),
              let userId = UUID(uuidString: userIdString),
              case .success(let currentUser) = userRepository.fetchUser(id: userId) else {
            showToast(message: NSLocalizedString("Failed to publish post", comment: "Post publish failed toast"))
            return
        }

        guard !isGuestUser(currentUser) else {
            showLoginAlert()
            return
        }

        guard !content.isEmpty, !addressText.isEmpty, !selectedImages.isEmpty else {
            showToast(message: NSLocalizedString("Please complete post information", comment: "Post required fields toast"))
            return
        }

        let walletKey = makeWalletKey(for: currentUser)
        let shouldBoostPost = isBoostSelected
        if shouldBoostPost {
            guard WalletKeychainStore.balance(for: walletKey) >= Constants.publishCost else {
                showToast(message: NSLocalizedString("Insufficient balance", comment: "Post insufficient wallet balance toast"))
                showWallet()
                return
            }
        }

        let imagePaths = selectedImages.compactMap(savePostImage)
        guard imagePaths.count == selectedImages.count else {
            showToast(message: NSLocalizedString("Failed to save post images", comment: "Post image save failed toast"))
            return
        }

        var didDeductBoostCost = false
        if shouldBoostPost {
            guard WalletKeychainStore.deduct(Constants.publishCost, for: walletKey) else {
                showToast(message: NSLocalizedString("Insufficient balance", comment: "Post insufficient wallet balance toast"))
                showWallet()
                return
            }
            didDeductBoostCost = true
        }

        let result = postRepository.createPost(
            author: currentUser,
            title: makePostTitle(from: content),
            content: content,
            addressText: addressText,
            imagePaths: imagePaths,
            isBoosted: shouldBoostPost
        )

        switch result {
        case .success:
            showToast(message: NSLocalizedString("Post published", comment: "Post publish success toast"))
            NotificationCenter.default.post(name: .postDidPublish, object: nil)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { [weak self] in
                self?.dismiss(animated: true)
            }
        case .failure:
            if didDeductBoostCost {
                _ = WalletKeychainStore.add(Constants.publishCost, for: walletKey)
            }
            showToast(message: NSLocalizedString("Failed to publish post", comment: "Post publish failed toast"))
        }
    }

    @objc private func handleBoostTapped() {
        isBoostSelected.toggle()
    }

    private func updateBoostState() {
        boostButton.isSelected = isBoostSelected
        boostBadgeView.backgroundColor = isBoostSelected
            ? UIColor(red: 0.87, green: 0.90, blue: 0.12, alpha: 1.0)
            : .white
        hotImageView.isHidden = !isBoostSelected
    }

    private func makeWalletKey(for user: User) -> String {
        "wallet.\(user.id.uuidString)"
    }

    private func showWallet() {
        let viewController = WalletViewController()
        viewController.modalPresentationStyle = .overFullScreen
        present(viewController, animated: true)
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

    private func makePostTitle(from content: String) -> String {
        let firstLine = content
            .components(separatedBy: .newlines)
            .first?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? content
        return String(firstLine.prefix(30))
    }

    private func savePostImage(_ image: UIImage) -> String? {
        guard let imageData = image.jpegData(compressionQuality: 0.88),
              let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }

        let postsDirectoryURL = documentsURL.appendingPathComponent("PostImages", isDirectory: true)
        do {
            try FileManager.default.createDirectory(at: postsDirectoryURL, withIntermediateDirectories: true)
            let imageName = "\(UUID().uuidString).jpg"
            let fileURL = postsDirectoryURL.appendingPathComponent(imageName)
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
            accessibilityIdentifier: "postToastLabel"
        )
    }
}

extension PostViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        selectedImages.count < 3 ? selectedImages.count + 1 : selectedImages.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: PostImageCollectionViewCell.reuseIdentifier,
            for: indexPath
        ) as? PostImageCollectionViewCell else {
            return UICollectionViewCell()
        }

        if selectedImages.indices.contains(indexPath.item) {
            cell.configure(item: PostImageItem(kind: .photo(selectedImages[indexPath.item])))
            cell.onRemove = { [weak self] in
                self?.removeImage(at: indexPath.item)
            }
        } else {
            cell.configure(item: PostImageItem(kind: .add))
            cell.onRemove = nil
        }
        return cell
    }
}

extension PostViewController: UICollectionViewDelegate {
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

extension PostViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
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

extension PostViewController: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        updatePlaceholderVisibility()
    }

    private func updatePlaceholderVisibility() {
        placeholderLabel.isHidden = !textView.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

private struct PostImageItem {
    enum Kind {
        case photo(UIImage)
        case add
    }

    let kind: Kind
}

private final class PostImageCollectionViewCell: UICollectionViewCell {
    static let reuseIdentifier = "PostImageCollectionViewCell"

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

    func configure(item: PostImageItem) {
        switch item.kind {
        case .photo(let image):
            imageView.image = image
            imageView.backgroundColor = .clear
            addIconView.isHidden = true
            removeButton.isHidden = false
        case .add:
            imageView.image = nil
            imageView.backgroundColor = .white
            addIconView.isHidden = false
            removeButton.isHidden = true
        }
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
