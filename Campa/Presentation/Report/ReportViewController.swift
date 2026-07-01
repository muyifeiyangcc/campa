import UIKit

final class ReportViewController: BaseViewController {
    private enum Constants {
        static let backgroundColor = UIColor(red: 0.98, green: 0.93, blue: 0.86, alpha: 1.0)
        static let purpleColor = UIColor(red: 0.72, green: 0.62, blue: 0.97, alpha: 1.0)
        static let darkTextColor = UIColor(red: 0.28, green: 0.02, blue: 0.02, alpha: 1.0)
        static let horizontalInset: CGFloat = 28
        static let optionHeight: CGFloat = 42
    }

    private let promptLabel = UILabel()
    private let optionStackView = UIStackView()
    private let othersLabel = UILabel()
    private let textView = UITextView()
    private let placeholderLabel = UILabel()
    private let submitButton = UIButton(type: .system)

    private var optionButtons: [UIButton] = []
    private var selectedOptionIndex = 0
    
    private let options = [
        NSLocalizedString("Malicious harassment", comment: "Report option"),
        NSLocalizedString("Pornographic content", comment: "Report option"),
        NSLocalizedString("Violent scenes", comment: "Report option"),
        NSLocalizedString("False information", comment: "Report option"),
        NSLocalizedString("Insulting language", comment: "Report option")
    ]

    override func viewDidLoad() {
        super.viewDidLoad()

        configureNavigation()
        configurePrompt()
        configureOptions()
        configureTextView()
        configureSubmitButton()
        configureLayout()
        updateOptionSelection()
        updatePlaceholderVisibility()
    }

    private func configureNavigation() {
        view.backgroundColor = Constants.backgroundColor
        navBar.backgroundColor = .clear
        changeNavbar(.back)
    }

    private func configurePrompt() {
        promptLabel.translatesAutoresizingMaskIntoConstraints = false
        promptLabel.text = NSLocalizedString("Please select the type of report:", comment: "Report prompt")
        promptLabel.font = AppFont.medium(size: 13)
        promptLabel.textColor = Constants.darkTextColor
        view.addSubview(promptLabel)
    }

    private func configureOptions() {
        optionStackView.translatesAutoresizingMaskIntoConstraints = false
        optionStackView.axis = .vertical
        optionStackView.spacing = 14

        optionButtons = options.enumerated().map { index, title in
            let button = UIButton(type: .system)
            button.tag = index
            button.setTitle(title, for: .normal)
            button.titleLabel?.font = AppFont.medium(size: 12)
            button.layer.cornerRadius = 6
            button.addTarget(self, action: #selector(optionButtonTapped(_:)), for: .touchUpInside)
            button.heightAnchor.constraint(equalToConstant: Constants.optionHeight).isActive = true
            return button
        }
        optionButtons.forEach(optionStackView.addArrangedSubview)
        view.addSubview(optionStackView)
    }

    private func configureTextView() {
        othersLabel.translatesAutoresizingMaskIntoConstraints = false
        othersLabel.text = NSLocalizedString("Others", comment: "Other report reason label")
        othersLabel.font = AppFont.medium(size: 13)
        othersLabel.textColor = Constants.darkTextColor

        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.backgroundColor = Constants.purpleColor
        textView.layer.cornerRadius = 12
        textView.clipsToBounds = true
        textView.font = AppFont.medium(size: 12)
        textView.textColor = Constants.darkTextColor
        textView.textContainerInset = UIEdgeInsets(top: 14, left: 12, bottom: 12, right: 12)
        textView.delegate = self

        placeholderLabel.translatesAutoresizingMaskIntoConstraints = false
        placeholderLabel.text = NSLocalizedString("Please describe any other reasons for the report.", comment: "Report text placeholder")
        placeholderLabel.font = AppFont.medium(size: 10)
        placeholderLabel.textColor = .white

        view.addSubview(othersLabel)
        view.addSubview(textView)
        textView.addSubview(placeholderLabel)
    }

    private func configureSubmitButton() {
        submitButton.translatesAutoresizingMaskIntoConstraints = false
        submitButton.setTitle(NSLocalizedString("Submit", comment: "Report submit button"), for: .normal)
        submitButton.setTitleColor(.white, for: .normal)
        submitButton.titleLabel?.font = AppFont.medium(size: 16)
        submitButton.backgroundColor = Constants.darkTextColor
        submitButton.layer.cornerRadius = 22
        submitButton.addTarget(self, action: #selector(clickSubmitAction), for: .touchUpInside)
        view.addSubview(submitButton)
    }

    @objc func clickSubmitAction() {
        AppLoading.show(in: self.view) { [weak self] in
            guard let self = self else { return }
            AppToast.show(
                message: "Submit successed!",
                in: view,
                relation: .above(view.centerYAnchor, spacing: 0),
                accessibilityIdentifier: "ReportToastLabel"
            )
        }
    }
    
    private func configureLayout() {
        NSLayoutConstraint.activate([
            promptLabel.topAnchor.constraint(equalTo: navBar.bottomAnchor, constant: 18),
            promptLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: Constants.horizontalInset),
            promptLabel.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -Constants.horizontalInset),

            optionStackView.topAnchor.constraint(equalTo: promptLabel.bottomAnchor, constant: 16),
            optionStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: Constants.horizontalInset + 10),
            optionStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -(Constants.horizontalInset + 10)),

            othersLabel.topAnchor.constraint(equalTo: optionStackView.bottomAnchor, constant: 18),
            othersLabel.leadingAnchor.constraint(equalTo: promptLabel.leadingAnchor),
            othersLabel.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -Constants.horizontalInset),

            textView.topAnchor.constraint(equalTo: othersLabel.bottomAnchor, constant: 12),
            textView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: Constants.horizontalInset),
            textView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -Constants.horizontalInset),
            textView.heightAnchor.constraint(equalToConstant: 210),

            placeholderLabel.topAnchor.constraint(equalTo: textView.topAnchor, constant: 16),
            placeholderLabel.leadingAnchor.constraint(equalTo: textView.leadingAnchor, constant: 16),
            placeholderLabel.trailingAnchor.constraint(lessThanOrEqualTo: textView.trailingAnchor, constant: -16),

            submitButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 72),
            submitButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -72),
            submitButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -44),
            submitButton.heightAnchor.constraint(equalToConstant: 44)
        ])
    }

    @objc private func optionButtonTapped(_ sender: UIButton) {
        selectedOptionIndex = sender.tag
        updateOptionSelection()
    }

    private func updateOptionSelection() {
        optionButtons.enumerated().forEach { index, button in
            let isSelected = index == selectedOptionIndex
            button.backgroundColor = isSelected ? Constants.purpleColor : .white
            button.setTitleColor(Constants.darkTextColor, for: .normal)
        }
    }

    private func updatePlaceholderVisibility() {
        placeholderLabel.isHidden = !textView.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

extension ReportViewController: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        updatePlaceholderVisibility()
    }
}
