import UIKit

final class EditProfileViewController: BaseViewController {
    private enum Constants {
        static let horizontalInset: CGFloat = 20
        static let avatarSize: CGFloat = 100
        static let badgeSize: CGFloat = 24
        static let fieldHeight: CGFloat = 54
        static let buttonHeight: CGFloat = 50
        static let textColor = UIColor(red: 0.28, green: 0.02, blue: 0.01, alpha: 1.0)
        static let backgroundColor = UIColor(red: 0.98, green: 0.93, blue: 0.86, alpha: 1.0)
    }

    private let userRepository: UserRepository
    private let avatarButton = UIButton(type: .custom)
    private let avatarImageView = UIImageView()
    private let editBadgeView = UIView()
    private let editBadgeImageView = UIImageView()
    private let usernameLabel = UILabel()
    private let usernameField = UITextField()
    private let saveButton = UIButton(type: .custom)

    private var currentUserId: UUID?
    private var currentAvatarLocalPath: String?

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
        configureAvatar()
        configureUsername()
        configureSaveButton()
        configureLayout()
        loadCurrentUser()
    }

    private func configureNavigation() {
        view.backgroundColor = Constants.backgroundColor
        navType = .backTiltle
        self.setTitleAndRight(title: NSLocalizedString("Edit Profile", comment: "Edit profile screen title"), right: nil)
    }

    private func configureAvatar() {
        avatarButton.translatesAutoresizingMaskIntoConstraints = false
        avatarButton.addTarget(self, action: #selector(handleAvatarTapped), for: .touchUpInside)

        avatarImageView.translatesAutoresizingMaskIntoConstraints = false
        avatarImageView.image = UIImage(named: "user_icon")
        avatarImageView.backgroundColor = .white
        avatarImageView.contentMode = .scaleAspectFill
        avatarImageView.layer.cornerRadius = Constants.avatarSize / 2
        avatarImageView.clipsToBounds = true
        avatarImageView.isUserInteractionEnabled = false

        editBadgeView.translatesAutoresizingMaskIntoConstraints = false
        editBadgeView.backgroundColor = .white
        editBadgeView.layer.cornerRadius = Constants.badgeSize / 2
        editBadgeView.clipsToBounds = true
        editBadgeView.isUserInteractionEnabled = false

        editBadgeImageView.translatesAutoresizingMaskIntoConstraints = false
        editBadgeImageView.image = UIImage(systemName: "pencil")
        editBadgeImageView.tintColor = Constants.textColor
        editBadgeImageView.contentMode = .scaleAspectFit
    }

    private func configureUsername() {
        usernameLabel.translatesAutoresizingMaskIntoConstraints = false
        usernameLabel.text = NSLocalizedString("Username", comment: "Edit profile username label")
        usernameLabel.font = AppFont.semibold(size: 12)
        usernameLabel.textColor = Constants.textColor

        usernameField.translatesAutoresizingMaskIntoConstraints = false
        usernameField.placeholder = NSLocalizedString("Enter username", comment: "Edit profile username placeholder")
        usernameField.textContentType = .username
        usernameField.autocapitalizationType = .words
        usernameField.font = AppFont.medium(size: 13)
        usernameField.textColor = Constants.textColor
        usernameField.backgroundColor = .white
        usernameField.layer.cornerRadius = Constants.fieldHeight / 2
        usernameField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 18, height: Constants.fieldHeight))
        usernameField.leftViewMode = .always
        usernameField.rightView = UIView(frame: CGRect(x: 0, y: 0, width: 18, height: Constants.fieldHeight))
        usernameField.rightViewMode = .always
        usernameField.accessibilityIdentifier = "editProfileUsernameField"
    }

    private func configureSaveButton() {
        saveButton.translatesAutoresizingMaskIntoConstraints = false
        saveButton.setTitle(NSLocalizedString("Save", comment: "Edit profile save button"), for: .normal)
        saveButton.setTitleColor(.white, for: .normal)
        saveButton.titleLabel?.font = AppFont.semibold(size: 14)
        saveButton.backgroundColor = Constants.textColor
        saveButton.layer.cornerRadius = Constants.buttonHeight / 2
        saveButton.accessibilityIdentifier = "editProfileSaveButton"
        saveButton.addTarget(self, action: #selector(handleSaveTapped), for: .touchUpInside)
    }

    private func configureLayout() {
        view.addSubview(avatarButton)
        avatarButton.addSubview(avatarImageView)
        avatarButton.addSubview(editBadgeView)
        editBadgeView.addSubview(editBadgeImageView)
        view.addSubview(usernameLabel)
        view.addSubview(usernameField)
        view.addSubview(saveButton)
        view.bringSubviewToFront(navBar)

        NSLayoutConstraint.activate([
            avatarButton.topAnchor.constraint(equalTo: navBar.bottomAnchor, constant: 38),
            avatarButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            avatarButton.widthAnchor.constraint(equalToConstant: Constants.avatarSize),
            avatarButton.heightAnchor.constraint(equalToConstant: Constants.avatarSize),

            avatarImageView.topAnchor.constraint(equalTo: avatarButton.topAnchor),
            avatarImageView.leadingAnchor.constraint(equalTo: avatarButton.leadingAnchor),
            avatarImageView.trailingAnchor.constraint(equalTo: avatarButton.trailingAnchor),
            avatarImageView.bottomAnchor.constraint(equalTo: avatarButton.bottomAnchor),

            editBadgeView.trailingAnchor.constraint(equalTo: avatarButton.trailingAnchor, constant: -4),
            editBadgeView.bottomAnchor.constraint(equalTo: avatarButton.bottomAnchor, constant: -4),
            editBadgeView.widthAnchor.constraint(equalToConstant: Constants.badgeSize),
            editBadgeView.heightAnchor.constraint(equalToConstant: Constants.badgeSize),

            editBadgeImageView.centerXAnchor.constraint(equalTo: editBadgeView.centerXAnchor),
            editBadgeImageView.centerYAnchor.constraint(equalTo: editBadgeView.centerYAnchor),
            editBadgeImageView.widthAnchor.constraint(equalToConstant: 12),
            editBadgeImageView.heightAnchor.constraint(equalToConstant: 12),

            usernameLabel.topAnchor.constraint(equalTo: avatarButton.bottomAnchor, constant: 42),
            usernameLabel.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: Constants.horizontalInset),

            usernameField.topAnchor.constraint(equalTo: usernameLabel.bottomAnchor, constant: 12),
            usernameField.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: Constants.horizontalInset),
            usernameField.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -Constants.horizontalInset),
            usernameField.heightAnchor.constraint(equalToConstant: Constants.fieldHeight),

            saveButton.topAnchor.constraint(equalTo: usernameField.bottomAnchor, constant: 110),
            saveButton.leadingAnchor.constraint(equalTo: usernameField.leadingAnchor),
            saveButton.trailingAnchor.constraint(equalTo: usernameField.trailingAnchor),
            saveButton.heightAnchor.constraint(equalToConstant: Constants.buttonHeight)
        ])
    }

    private func loadCurrentUser() {
        guard let userIdString = UserDefaults.standard.string(forKey: CurrentUserIdKey),
              let userId = UUID(uuidString: userIdString),
              case .success(let user) = userRepository.fetchUser(id: userId) else {
            showToast(message: NSLocalizedString("Failed to load profile", comment: "Edit profile load failed toast"))
            return
        }

        currentUserId = userId
        usernameField.text = user.nickname
        currentAvatarLocalPath = cleanedText(user.avatarLocalPath)
        updateAvatarImage()
    }

    private func updateAvatarImage() {
        avatarImageView.image = UIImage.sandboxOrAssetImage(
            named: currentAvatarLocalPath,
            documentsSubdirectory: "Avatars",
            fallbackName: "user_icon"
        )
    }

    @objc private func handleAvatarTapped() {
        guard UIImagePickerController.isSourceTypeAvailable(.photoLibrary) else {
            showToast(message: NSLocalizedString("Photo library unavailable", comment: "Edit profile photo library unavailable toast"))
            return
        }

        let picker = UIImagePickerController()
        picker.sourceType = .photoLibrary
        picker.allowsEditing = true
        picker.delegate = self
        present(picker, animated: true)
    }

    @objc private func handleSaveTapped() {
        guard let currentUserId else {
            showToast(message: NSLocalizedString("Failed to save profile", comment: "Edit profile save failed toast"))
            return
        }

        let nickname = usernameField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !nickname.isEmpty else {
            showToast(message: NSLocalizedString("Please enter username", comment: "Edit profile username required toast"))
            return
        }
        AppLoading.show(in: self.view) { [weak self] in
            guard let self = self else { return }
            switch userRepository.updateUser(id: currentUserId, nickname: nickname, avatarLocalPath: self.currentAvatarLocalPath) {
            case .success:
                self.showToast(message: NSLocalizedString("Profile saved", comment: "Edit profile saved toast"))
            case .failure:
                self.showToast(message: NSLocalizedString("Failed to save profile", comment: "Edit profile save failed toast"))
            }
        }
    }

    private func saveAvatarImage(_ image: UIImage) -> String? {
        guard let imageData = image.jpegData(compressionQuality: 0.88),
              let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }

        let avatarsDirectoryURL = documentsURL.appendingPathComponent("Avatars", isDirectory: true)
        do {
            try FileManager.default.createDirectory(at: avatarsDirectoryURL, withIntermediateDirectories: true)
            let imageName = "\(UUID().uuidString).jpg"
            let fileURL = avatarsDirectoryURL.appendingPathComponent(imageName)
            try imageData.write(to: fileURL, options: .atomic)
            return imageName
        } catch {
            return nil
        }
    }

    private func avatarFileURL(for storedPath: String) -> URL? {
        let value = storedPath.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty else {
            return nil
        }

        if value.hasPrefix("/") {
            return URL(fileURLWithPath: value)
        }

        guard let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }

        return documentsURL
            .appendingPathComponent("Avatars", isDirectory: true)
            .appendingPathComponent(value)
    }

    private func cleanedText(_ text: String?) -> String? {
        let value = text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return value.isEmpty ? nil : value
    }

    private func showToast(message: String) {
        AppToast.show(
            message: message,
            in: view,
            relation: .above(saveButton.topAnchor, spacing: 18),
            accessibilityIdentifier: "editProfileToastLabel"
        )
    }
}

extension EditProfileViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(
        _ picker: UIImagePickerController,
        didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
    ) {
        let image = (info[.editedImage] as? UIImage) ?? (info[.originalImage] as? UIImage)
        if let image, let avatarLocalPath = saveAvatarImage(image) {
            avatarImageView.image = image
            currentAvatarLocalPath = avatarLocalPath
        } else {
            showToast(message: NSLocalizedString("Failed to save avatar", comment: "Edit profile avatar save failed toast"))
        }
        picker.dismiss(animated: true)
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
}
