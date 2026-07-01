import UIKit

final class MainTabBarController: UITabBarController {
    private enum Constants {
        static let tabBarHeight: CGFloat = 86
        static let horizontalInset: CGFloat = 14
        static let centerButtonSize: CGFloat = 36
        static let itemButtonSize: CGFloat = 48
    }

    private let customTabBarView = UIView()
    private let tabBackgroundImageView = UIImageView()
    private let centerButton = UIButton(type: .custom)
    private var itemButtons: [UIButton] = []
    private let tabItems: [CustomTabItem] = [
        CustomTabItem(imageName: "home", selectedImageName: "home_sel", index: 0),
        CustomTabItem(imageName: "build", selectedImageName: "build_sel", index: 1),
        CustomTabItem(imageName: "bell", selectedImageName: "bell_sel", index: 2),
        CustomTabItem(imageName: "user_set", selectedImageName: "user_set_sel", index: 3)
    ]

    override func viewDidLoad() {
        super.viewDidLoad()

        delegate = self
        configureViewControllers()
        configureSystemTabBar()
        configureCustomTabBar()
        updateSelectedTab(index: selectedIndex)
        updateCustomTabBarVisibility(animated: false)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        view.bringSubviewToFront(customTabBarView)
        view.bringSubviewToFront(centerButton)
    }

    private func configureViewControllers() {
        viewControllers = [
            makeTab(makeNavigationController(rootViewController: HomeViewController()), title: NSLocalizedString("Home", comment: "Home tab title"), imageName: "home", selectedImageName: "home_sel"),
            makeTab(makeNavigationController(rootViewController: CampusViewController()), title: NSLocalizedString("Campus", comment: "Campus tab title"), imageName: "build", selectedImageName: "build_sel"),
            makeTab(makeNavigationController(rootViewController: MessageListViewController()), title: NSLocalizedString("Message", comment: "Messages tab title"), imageName: "bell", selectedImageName: "bell_sel"),
            makeTab(makeNavigationController(rootViewController: ProfileViewController()), title: NSLocalizedString("Me", comment: "Profile tab title"), imageName: "user_set", selectedImageName: "user_set_sel")
        ]
    }

    private func makeNavigationController(rootViewController: UIViewController) -> UINavigationController {
        let navigationController = UINavigationController(rootViewController: rootViewController)
        navigationController.delegate = self
        return navigationController
    }

    private func makeTab(_ viewController: UIViewController, title: String, imageName: String, selectedImageName: String) -> UIViewController {
        viewController.tabBarItem = UITabBarItem(
            title: nil,
            image: UIImage(named: imageName),
            selectedImage: UIImage(named: selectedImageName)
        )
        return viewController
    }

    private func configureSystemTabBar() {
        tabBar.isHidden = true
    }

    private func configureCustomTabBar() {
        customTabBarView.translatesAutoresizingMaskIntoConstraints = false
        customTabBarView.backgroundColor = .clear
        customTabBarView.clipsToBounds = false

        tabBackgroundImageView.translatesAutoresizingMaskIntoConstraints = false
        tabBackgroundImageView.image = UIImage(named: "tab_bg")
        tabBackgroundImageView.contentMode = .scaleToFill
        tabBackgroundImageView.clipsToBounds = false

        centerButton.translatesAutoresizingMaskIntoConstraints = false
        centerButton.setImage(UIImage(named: "tab_add"), for: .normal)
        centerButton.backgroundColor = .white
        centerButton.layer.cornerRadius = Constants.centerButtonSize / 2
        centerButton.layer.shadowColor = UIColor.black.cgColor
        centerButton.layer.shadowOpacity = 0.12
        centerButton.layer.shadowOffset = CGSize(width: 0, height: 4)
        centerButton.layer.shadowRadius = 10
        centerButton.accessibilityIdentifier = "mainTabCenterButton"
        centerButton.addTarget(self, action: #selector(clickCenterAction), for: .touchUpInside)
        
        view.addSubview(customTabBarView)
        customTabBarView.addSubview(tabBackgroundImageView)
        tabItems.map(makeItemButton(item:)).forEach { button in
            itemButtons.append(button)
            customTabBarView.addSubview(button)
        }
        view.addSubview(centerButton)

        NSLayoutConstraint.activate([
            customTabBarView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            customTabBarView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            customTabBarView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            customTabBarView.heightAnchor.constraint(equalToConstant: Constants.tabBarHeight),

            tabBackgroundImageView.topAnchor.constraint(equalTo: customTabBarView.topAnchor),
            tabBackgroundImageView.leadingAnchor.constraint(equalTo: customTabBarView.leadingAnchor),
            tabBackgroundImageView.trailingAnchor.constraint(equalTo: customTabBarView.trailingAnchor),
            tabBackgroundImageView.bottomAnchor.constraint(equalTo: customTabBarView.bottomAnchor),

            centerButton.centerXAnchor.constraint(equalTo: customTabBarView.centerXAnchor),
            centerButton.topAnchor.constraint(equalTo: customTabBarView.topAnchor, constant: -24),
            centerButton.widthAnchor.constraint(equalToConstant: Constants.centerButtonSize),
            centerButton.heightAnchor.constraint(equalToConstant: Constants.centerButtonSize)
        ])

        configureItemButtonLayout()
    }

    @objc func clickCenterAction() {
        let vc = PostViewController()
        vc.modalPresentationStyle = .overFullScreen
        self.present(vc, animated: false)
    }
    
    private func configureItemButtonLayout() {
        guard itemButtons.count == 4 else {
            return
        }

        NSLayoutConstraint.activate([
            itemButtons[0].leadingAnchor.constraint(equalTo: customTabBarView.leadingAnchor, constant: 32),
            itemButtons[0].centerYAnchor.constraint(equalTo: customTabBarView.topAnchor, constant: 30),

            itemButtons[1].leadingAnchor.constraint(equalTo: itemButtons[0].trailingAnchor, constant: 32),
            itemButtons[1].centerYAnchor.constraint(equalTo: itemButtons[0].centerYAnchor),

            itemButtons[2].trailingAnchor.constraint(equalTo: itemButtons[3].leadingAnchor, constant: -32),
            itemButtons[2].centerYAnchor.constraint(equalTo: itemButtons[0].centerYAnchor),

            itemButtons[3].trailingAnchor.constraint(equalTo: customTabBarView.trailingAnchor, constant: -32),
            itemButtons[3].centerYAnchor.constraint(equalTo: itemButtons[0].centerYAnchor)
        ])

        itemButtons.forEach { button in
            NSLayoutConstraint.activate([
                button.widthAnchor.constraint(equalToConstant: Constants.itemButtonSize),
                button.heightAnchor.constraint(equalToConstant: Constants.itemButtonSize)
            ])
        }
    }

    private func makeItemButton(item: CustomTabItem) -> UIButton {
        let button = UIButton(type: .custom)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(UIImage(named: item.imageName), for: .normal)
        button.setImage(UIImage(named: item.selectedImageName), for: .selected)
        button.imageView?.contentMode = .scaleAspectFit
        button.tag = item.index
        button.accessibilityIdentifier = "mainTabItem\(item.index)"
        button.addTarget(self, action: #selector(handleItemButtonTapped(_:)), for: .touchUpInside)
        return button
    }

    private func updateSelectedTab(index: Int) {
        selectedIndex = index
        itemButtons.forEach { button in
            button.isSelected = button.tag == index
        }
        updateCustomTabBarVisibility(animated: false)
    }

    private func updateCustomTabBarVisibility(animated: Bool) {
        let shouldHide = selectedNavigationController?.viewControllers.count ?? 1 > 1
        setCustomTabBarHidden(shouldHide, animated: true)
    }

    private func setCustomTabBarHidden(_ hidden: Bool, animated: Bool) {
        guard customTabBarView.isHidden != hidden else {
            return
        }

        let alpha: CGFloat = hidden ? 0 : 1
        let updates = {
            self.customTabBarView.alpha = alpha
            self.centerButton.alpha = alpha
        }

        if hidden {
            updates()
            customTabBarView.isHidden = true
            centerButton.isHidden = true
            return
        }

        customTabBarView.isHidden = false
        centerButton.isHidden = false

        guard animated else {
            updates()
            return
        }

        customTabBarView.alpha = 0
        centerButton.alpha = 0
        UIView.animate(withDuration: 0.1, animations: updates)
    }

    private var selectedNavigationController: UINavigationController? {
        selectedViewController as? UINavigationController
    }

    @objc private func handleItemButtonTapped(_ sender: UIButton) {
        updateSelectedTab(index: sender.tag)
    }

    func switchToProfileTab() {
        viewControllers?
            .compactMap { $0 as? UINavigationController }
            .forEach { $0.popToRootViewController(animated: false) }
        updateSelectedTab(index: 3)
    }
}

extension MainTabBarController: UITabBarControllerDelegate, UINavigationControllerDelegate {
    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        updateCustomTabBarVisibility(animated: false)
    }

    func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        guard navigationController === selectedNavigationController else {
            return
        }

        updateCustomTabBarVisibility(animated: false)
    }
}

private struct CustomTabItem {
    let imageName: String
    let selectedImageName: String
    let index: Int
}

private final class TabPlaceholderViewController: UIViewController {
    private let screenTitle: String
    private let titleLabel = UILabel()

    init(title: String) {
        self.screenTitle = title
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        configureView()
        configureTitleLabel()
    }

    private func configureView() {
        view.backgroundColor = UIColor(red: 0.98, green: 0.93, blue: 0.86, alpha: 1.0)
    }

    private func configureTitleLabel() {
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = screenTitle
        titleLabel.font = AppFont.semibold(size: 22)
        titleLabel.textColor = UIColor(red: 0.28, green: 0.20, blue: 0.16, alpha: 1.0)
        titleLabel.textAlignment = .center

        view.addSubview(titleLabel)

        NSLayoutConstraint.activate([
            titleLabel.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor)
        ])
    }
}
