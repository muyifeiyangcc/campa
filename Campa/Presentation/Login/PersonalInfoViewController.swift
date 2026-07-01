import UIKit

final class PersonalInfoViewController: BaseViewController {
    private enum Constants {
        static let horizontalInset: CGFloat = 28
        static let fieldHeight: CGFloat = 48
        static let fieldCornerRadius: CGFloat = 24
        static let buttonHeight: CGFloat = 58
        static let selectedColor = UIColor(red: 0.69, green: 0.59, blue: 0.96, alpha: 1.0)
        static let textColor = UIColor(red: 0.28, green: 0.02, blue: 0.01, alpha: 1.0)
    }

    private let viewModel: PersonalInfoViewModel
    private let registrationDraft: SignUpRegistrationDraft?
    private let userRepository: UserRepository
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let avatarContainer = UIView()
    private let avatarImageView = UIImageView()
    private let cameraBadgeView = UIView()
    private let cameraImageView = UIImageView()
    private let nameLabel = UILabel()
    private let nameField = PersonalInfoTextField()
    private let birthdayLabel = UILabel()
    private let birthdayField = PersonalInfoTextField()
    private let locationLabel = UILabel()
    private let locationField = PersonalInfoTextField()
    private let genderLabel = UILabel()
    private let maleButton = UIButton(type: .custom)
    private let femaleButton = UIButton(type: .custom)
    private let saveButton = UIButton(type: .custom)
    private let datePicker = UIDatePicker()
    private let universityPicker = UIPickerView()
    private let birthdayFormatter = DateFormatter()

    private var selectedGender: PersonalInfoGender
    private var selectedUniversityIndex = 0
    private var selectedAvatarLocalPath: String?

    init(
        registrationDraft: SignUpRegistrationDraft? = nil,
        viewModel: PersonalInfoViewModel = PersonalInfoViewModel(),
        userRepository: UserRepository = UserRepository()
    ) {
        self.viewModel = viewModel
        self.registrationDraft = registrationDraft
        self.userRepository = userRepository
        self.selectedGender = viewModel.defaultGender
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        navType = .back
        configureFormatter()
        configureScrollView()
        configureAvatar()
        configureLabels()
        configureFields()
        configureGenderButtons()
        configureSaveButton()
        configureLayout()
        updateGenderButtons()
    }

    private func configureFormatter() {
        birthdayFormatter.dateFormat = "yyyy-MM-dd"
        birthdayFormatter.locale = Locale(identifier: "en_US_POSIX")
    }

    private func configureScrollView() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.alwaysBounceVertical = true
        contentView.translatesAutoresizingMaskIntoConstraints = false
    }

    private func configureAvatar() {
        avatarContainer.translatesAutoresizingMaskIntoConstraints = false
        avatarContainer.backgroundColor = UIColor(red: 233/255.0, green: 252/255.0, blue: 136/255.0, alpha: 1.0)
        avatarContainer.layer.cornerRadius = 46
        avatarContainer.clipsToBounds = false

        avatarImageView.translatesAutoresizingMaskIntoConstraints = false
        avatarImageView.image = UIImage(named: "user_icon") ?? UIImage(named: "photo")
        avatarImageView.backgroundColor = .white
        avatarImageView.contentMode = .scaleAspectFill
        avatarImageView.layer.cornerRadius = 40
        avatarImageView.clipsToBounds = true

        cameraBadgeView.translatesAutoresizingMaskIntoConstraints = false
        cameraBadgeView.backgroundColor = UIColor(red: 0.56, green: 0.56, blue: 0.56, alpha: 1.0)
        cameraBadgeView.layer.cornerRadius = 13
        cameraBadgeView.clipsToBounds = true

        cameraImageView.translatesAutoresizingMaskIntoConstraints = false
        cameraImageView.image = UIImage(named: "photo")
        cameraImageView.contentMode = .scaleAspectFit
        cameraImageView.tintColor = .white

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleAvatarTapped))
        avatarContainer.addGestureRecognizer(tapGesture)
        avatarContainer.isUserInteractionEnabled = true
        avatarImageView.isUserInteractionEnabled = true
    }

    private func configureLabels() {
        [nameLabel, birthdayLabel, locationLabel, genderLabel].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            $0.font = AppFont.semibold(size: 14)
            $0.textColor = Constants.textColor
        }

        nameLabel.text = viewModel.nameTitle
        birthdayLabel.text = viewModel.birthdayTitle
        locationLabel.text = viewModel.locationTitle
        genderLabel.text = viewModel.genderTitle
    }

    private func configureFields() {
        nameField.translatesAutoresizingMaskIntoConstraints = false
        nameField.placeholder = viewModel.namePlaceholder
        nameField.textContentType = .name
        nameField.autocapitalizationType = .words
        nameField.accessibilityIdentifier = "personalInfoNameField"

        birthdayField.translatesAutoresizingMaskIntoConstraints = false
        birthdayField.placeholder = viewModel.birthdayPlaceholder
        birthdayField.inputView = datePicker
        birthdayField.inputAccessoryView = makePickerToolbar(doneAction: #selector(handleBirthdayDone))
        birthdayField.rightIconImage = UIImage(named: "down")
        birthdayField.isSelectionOnly = true
        birthdayField.delegate = self
        birthdayField.accessibilityIdentifier = "personalInfoBirthdayField"

        datePicker.datePickerMode = .date
        datePicker.preferredDatePickerStyle = .wheels
        datePicker.maximumDate = Date()

        locationField.translatesAutoresizingMaskIntoConstraints = false
        locationField.placeholder = viewModel.locationPlaceholder
        locationField.inputView = universityPicker
        locationField.inputAccessoryView = makePickerToolbar(doneAction: #selector(handleLocationDone))
        locationField.rightIconImage = UIImage(named: "down")
        locationField.isSelectionOnly = true
        locationField.delegate = self
        locationField.accessibilityIdentifier = "personalInfoLocationField"

        universityPicker.dataSource = self
        universityPicker.delegate = self
    }

    private func configureGenderButtons() {
        configureGenderButton(maleButton, title: viewModel.maleTitle, action: #selector(handleMaleTapped))
        configureGenderButton(femaleButton, title: viewModel.femaleTitle, action: #selector(handleFemaleTapped))
    }

    private func configureGenderButton(_ button: UIButton, title: String, action: Selector) {
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle(title, for: .normal)
        button.setTitleColor(Constants.textColor, for: .normal)
        button.titleLabel?.font = AppFont.medium(size: 12)
        button.layer.cornerRadius = 19
        button.layer.borderColor = Constants.selectedColor.cgColor
        button.layer.borderWidth = 0
        button.accessibilityIdentifier = "personalInfo\(title)Button"
        button.addTarget(self, action: action, for: .touchUpInside)
    }

    private func configureSaveButton() {
        saveButton.translatesAutoresizingMaskIntoConstraints = false
        saveButton.setTitle(viewModel.saveTitle, for: .normal)
        saveButton.setTitleColor(.white, for: .normal)
        saveButton.titleLabel?.font = AppFont.semibold(size: 18)
        saveButton.backgroundColor = Constants.textColor
        saveButton.layer.cornerRadius = Constants.buttonHeight / 2
        saveButton.accessibilityIdentifier = "personalInfoSaveButton"
        saveButton.addTarget(self, action: #selector(handleSaveTapped), for: .touchUpInside)
    }

    private func configureLayout() {
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        contentView.addSubview(avatarContainer)
        avatarContainer.addSubview(avatarImageView)
        avatarContainer.addSubview(cameraBadgeView)
        cameraBadgeView.addSubview(cameraImageView)
        contentView.addSubview(nameLabel)
        contentView.addSubview(nameField)
        contentView.addSubview(birthdayLabel)
        contentView.addSubview(birthdayField)
        contentView.addSubview(locationLabel)
        contentView.addSubview(locationField)
        contentView.addSubview(genderLabel)
        contentView.addSubview(maleButton)
        contentView.addSubview(femaleButton)
        contentView.addSubview(saveButton)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: navBar.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),

            avatarContainer.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            avatarContainer.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            avatarContainer.widthAnchor.constraint(equalToConstant: 92),
            avatarContainer.heightAnchor.constraint(equalToConstant: 92),

            avatarImageView.centerXAnchor.constraint(equalTo: avatarContainer.centerXAnchor),
            avatarImageView.centerYAnchor.constraint(equalTo: avatarContainer.centerYAnchor),
            avatarImageView.widthAnchor.constraint(equalToConstant: 78),
            avatarImageView.heightAnchor.constraint(equalToConstant: 78),

            cameraBadgeView.trailingAnchor.constraint(equalTo: avatarContainer.trailingAnchor, constant: -10),
            cameraBadgeView.bottomAnchor.constraint(equalTo: avatarContainer.bottomAnchor, constant: -8),
            cameraBadgeView.widthAnchor.constraint(equalToConstant: 26),
            cameraBadgeView.heightAnchor.constraint(equalToConstant: 26),

            cameraImageView.centerXAnchor.constraint(equalTo: cameraBadgeView.centerXAnchor),
            cameraImageView.centerYAnchor.constraint(equalTo: cameraBadgeView.centerYAnchor),
            cameraImageView.widthAnchor.constraint(equalToConstant: 14),
            cameraImageView.heightAnchor.constraint(equalToConstant: 14),

            nameLabel.topAnchor.constraint(equalTo: avatarContainer.bottomAnchor, constant: 18),
            nameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: Constants.horizontalInset),

            nameField.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 8),
            nameField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: Constants.horizontalInset),
            nameField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -Constants.horizontalInset),
            nameField.heightAnchor.constraint(equalToConstant: Constants.fieldHeight),

            birthdayLabel.topAnchor.constraint(equalTo: nameField.bottomAnchor, constant: 18),
            birthdayLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),

            birthdayField.topAnchor.constraint(equalTo: birthdayLabel.bottomAnchor, constant: 8),
            birthdayField.leadingAnchor.constraint(equalTo: nameField.leadingAnchor),
            birthdayField.trailingAnchor.constraint(equalTo: nameField.trailingAnchor),
            birthdayField.heightAnchor.constraint(equalToConstant: Constants.fieldHeight),

            locationLabel.topAnchor.constraint(equalTo: birthdayField.bottomAnchor, constant: 18),
            locationLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),

            locationField.topAnchor.constraint(equalTo: locationLabel.bottomAnchor, constant: 8),
            locationField.leadingAnchor.constraint(equalTo: nameField.leadingAnchor),
            locationField.trailingAnchor.constraint(equalTo: nameField.trailingAnchor),
            locationField.heightAnchor.constraint(equalToConstant: Constants.fieldHeight),

            genderLabel.topAnchor.constraint(equalTo: locationField.bottomAnchor, constant: 18),
            genderLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),

            maleButton.topAnchor.constraint(equalTo: genderLabel.bottomAnchor, constant: 14),
            maleButton.leadingAnchor.constraint(equalTo: nameField.leadingAnchor),
            maleButton.widthAnchor.constraint(equalToConstant: 82),
            maleButton.heightAnchor.constraint(equalToConstant: 38),

            femaleButton.centerYAnchor.constraint(equalTo: maleButton.centerYAnchor),
            femaleButton.leadingAnchor.constraint(equalTo: maleButton.trailingAnchor, constant: 42),
            femaleButton.widthAnchor.constraint(equalToConstant: 94),
            femaleButton.heightAnchor.constraint(equalToConstant: 38),

            saveButton.topAnchor.constraint(equalTo: maleButton.bottomAnchor, constant: 42),
            saveButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 68),
            saveButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -68),
            saveButton.heightAnchor.constraint(equalToConstant: Constants.buttonHeight),
            saveButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -34)
        ])
    }

    private func makePickerToolbar(doneAction: Selector) -> UIToolbar {
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        toolbar.items = [
            UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
            UIBarButtonItem(title: NSLocalizedString("Done", comment: "Picker done button"), style: .done, target: self, action: doneAction)
        ]
        return toolbar
    }

    private func updateGenderButtons() {
        updateGenderButton(maleButton, isSelected: selectedGender == .male)
        updateGenderButton(femaleButton, isSelected: selectedGender == .female)
    }

    private func updateGenderButton(_ button: UIButton, isSelected: Bool) {
        button.backgroundColor = isSelected ? Constants.selectedColor : .white
        button.layer.borderWidth = isSelected ? 0 : 1
    }

    @objc private func handleBirthdayDone() {
        birthdayField.text = birthdayFormatter.string(from: datePicker.date)
        birthdayField.resignFirstResponder()
    }

    @objc private func handleLocationDone() {
        guard !viewModel.universityNames.isEmpty else {
            locationField.resignFirstResponder()
            return
        }

        locationField.text = viewModel.universityNames[selectedUniversityIndex]
        locationField.resignFirstResponder()
    }

    @objc private func handleMaleTapped() {
        selectedGender = .male
        updateGenderButtons()
    }

    @objc private func handleFemaleTapped() {
        selectedGender = .female
        updateGenderButtons()
    }

    @objc private func handleAvatarTapped() {
        guard UIImagePickerController.isSourceTypeAvailable(.photoLibrary) else {
            return
        }

        let picker = UIImagePickerController()
        picker.sourceType = .photoLibrary
        picker.allowsEditing = true
        picker.delegate = self
        present(picker, animated: true)
    }

    @objc private func handleSaveTapped() {
        guard let registrationDraft else {
            showToast(message: viewModel.missingRegistrationMessage)
            return
        }

        let nickname = nameField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let location = locationField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        guard !nickname.isEmpty, !location.isEmpty, let birthday = selectedBirthday else {
            showToast(message: viewModel.requiredInfoMessage)
            return
        }

        guard let selectedAvatarLocalPath else {
            showToast(message: viewModel.requiredAvatarMessage)
            return
        }

        let result = userRepository.createRegisteredCurrentUser(
            email: registrationDraft.email,
            passwordHash: registrationDraft.passwordHash,
            nickname: nickname,
            birthday: birthday,
            location: location,
            gender: selectedGender.rawValue,
            avatarLocalPath: selectedAvatarLocalPath
        )

        switch result {
        case .success(let user):
            AppLoading.show(in: self.view) { [weak self] in
                guard let self = self else { return }
                UserDefaults.standard.set(user.id.uuidString, forKey: CurrentUserIdKey)
                self.switchToMainTabBarController()
            }
        case .failure:
            showToast(message: viewModel.saveFailedMessage)
        }
    }

    private func switchToMainTabBarController() {
        guard let window = view.window else { return }

        window.rootViewController = MainTabBarController()
        window.makeKeyAndVisible()
    }

    private var selectedBirthday: Date? {
        guard let text = birthdayField.text, !text.isEmpty else {
            return nil
        }

        return birthdayFormatter.date(from: text)
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

    private func showToast(message: String) {
        AppToast.show(
            message: message,
            in: view,
            relation: .above(saveButton.topAnchor, spacing: 18),
            accessibilityIdentifier: "personalInfoToastLabel"
        )
    }
}

extension PersonalInfoViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(
        _ picker: UIImagePickerController,
        didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
    ) {
        let image = (info[.editedImage] as? UIImage) ?? (info[.originalImage] as? UIImage)
        if let image {
            avatarImageView.image = image
            selectedAvatarLocalPath = saveAvatarImage(image)
        }
        picker.dismiss(animated: true)
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
}

extension PersonalInfoViewController: UITextFieldDelegate {
    func textField(
        _ textField: UITextField,
        shouldChangeCharactersIn range: NSRange,
        replacementString string: String
    ) -> Bool {
        textField !== birthdayField && textField !== locationField
    }
}

extension PersonalInfoViewController: UIPickerViewDataSource, UIPickerViewDelegate {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        1
    }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        viewModel.universityNames.count
    }

    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        viewModel.universityNames[row]
    }

    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        selectedUniversityIndex = row
        locationField.text = viewModel.universityNames[row]
    }
}

private final class PersonalInfoTextField: UITextField {
    var rightIconImage: UIImage? {
        didSet {
            configureRightView()
        }
    }
    var isSelectionOnly = false

    override init(frame: CGRect) {
        super.init(frame: frame)

        configure()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }

    override func textRect(forBounds bounds: CGRect) -> CGRect {
        bounds.inset(by: textInsets)
    }

    override func editingRect(forBounds bounds: CGRect) -> CGRect {
        textRect(forBounds: bounds)
    }

    override func placeholderRect(forBounds bounds: CGRect) -> CGRect {
        textRect(forBounds: bounds)
    }

    override func caretRect(for position: UITextPosition) -> CGRect {
        isSelectionOnly ? .zero : super.caretRect(for: position)
    }

    override func selectionRects(for range: UITextRange) -> [UITextSelectionRect] {
        isSelectionOnly ? [] : super.selectionRects(for: range)
    }

    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        isSelectionOnly ? false : super.canPerformAction(action, withSender: sender)
    }

    private var textInsets: UIEdgeInsets {
        UIEdgeInsets(top: 0, left: 16, bottom: 0, right: rightIconImage == nil ? 16 : 42)
    }

    private func configure() {
        backgroundColor = UIColor(red: 0.69, green: 0.59, blue: 0.96, alpha: 1.0)
        layer.cornerRadius = 24
        clipsToBounds = true
        textColor = .white
        tintColor = .white
        font = AppFont.medium(size: 12)
    }

    private func configureRightView() {
        guard let rightIconImage else {
            rightView = nil
            rightViewMode = .never
            return
        }

        let imageView = UIImageView(image: rightIconImage)
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = UIColor(red: 0.82, green: 0.94, blue: 0.24, alpha: 1.0)
        let container = UIView(frame: CGRect(x: 0, y: 0, width: 38, height: 24))
        container.isUserInteractionEnabled = true
        container.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleRightIconTapped)))
        imageView.frame = CGRect(x: 8, y: 7, width: 12, height: 10)
        container.addSubview(imageView)
        rightView = container
        rightViewMode = .always
    }

    @objc private func handleRightIconTapped() {
        becomeFirstResponder()
    }

    override var placeholder: String? {
        didSet {
            guard let placeholder else {
                return
            }

            attributedPlaceholder = NSAttributedString(
                string: placeholder,
                attributes: [
                    .foregroundColor: UIColor.white.withAlphaComponent(0.45),
                    .font: AppFont.medium(size: 12)
                ]
            )
        }
    }
}
