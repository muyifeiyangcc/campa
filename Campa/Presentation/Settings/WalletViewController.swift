import Security
import StoreKit
import UIKit

final class WalletViewController: BaseViewController {
    private enum Constants {
        static let pageBackgroundColor = UIColor(red: 0.98, green: 0.94, blue: 0.87, alpha: 1.0)
        static let limeColor = UIColor(red: 0.86, green: 0.91, blue: 0.12, alpha: 1.0)
        static let darkTextColor = UIColor(red: 0.28, green: 0.02, blue: 0.02, alpha: 1.0)
        static let selectedColor = UIColor(red: 196 / 255.0, green: 187 / 255.0, blue: 254 / 255.0, alpha: 1.0)
        static let horizontalInset: CGFloat = 30
    }

    private let headerView = UIImageView()
    private let titleLabel = UILabel()
    private let balanceIconView = UIImageView()
    private let balanceLabel = UILabel()
    private let headerBackgroundImageView = UIImageView()
    private let collectionView: UICollectionView
    private let userRepository: UserRepository
    private var selectedProductIndex = 0
    private var storeProducts: [String: StoreKit.Product] = [:]
    private let products: [WalletProduct] = [
        WalletProduct(productId: "mumyizhsdfvsbpbb", amount: "400", price: "$0.99"),
        WalletProduct(productId: "uiowzrkitnxdaqvb", amount: "800", price: "$1.99"),
        WalletProduct(productId: "ifhgfdsazxcvbnmq", amount: "1780", price: "$3.99"),
        WalletProduct(productId: "yggwhyexpjawrqzk", amount: "2450", price: "$4.99"),
        WalletProduct(productId: "yuoficglaacdnrci", amount: "5150", price: "$9.99"),
        WalletProduct(productId: "diijztiisphqpmpv", amount: "10800", price: "$19.99"),
        WalletProduct(productId: "sazwsxedcrfvtgby", amount: "14900", price: "$29.99"),
        WalletProduct(productId: "dleeglukfmsofayo", amount: "29400", price: "$49.99"),
        WalletProduct(productId: "xkpwbxmqzfgvjrhs", amount: "34500", price: "$69.99"),
        WalletProduct(productId: "adlvqzvpnyfuojhc", amount: "63700", price: "$99.99"),
    ]

    init(userRepository: UserRepository = UserRepository()) {
        self.userRepository = userRepository
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = 14
        layout.minimumInteritemSpacing = 14
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
        configureHeader()
        configureProducts()
        configureLayout()
        updateBalance()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        updateBalance()
    }

    private func configureNavigation() {
        changeNavbar(.backTiltle)
        self.setTitleAndRight(title: "Wallet", right: nil)
    }

    override func backAction() {
        if let vs = self.navigationController?.viewControllers, vs.count > 1 {
            self.navigationController?.popViewController(animated: true)
        } else {
            self.dismiss(animated: false)
        }
    }
    private func configureHeader() {
        headerBackgroundImageView.translatesAutoresizingMaskIntoConstraints = false
        headerBackgroundImageView.image = UIImage(named: "bag_bg")
        headerBackgroundImageView.contentMode = .scaleAspectFill

        headerView.translatesAutoresizingMaskIntoConstraints = false
        headerView.image = UIImage(named: "wallet_bg")

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = NSLocalizedString("Wallet", comment: "Wallet title")
        titleLabel.font = AppFont.bold(size: 24)
        titleLabel.textColor = Constants.darkTextColor

        balanceIconView.translatesAutoresizingMaskIntoConstraints = false
        balanceIconView.image = UIImage(named: "vip_icon")
        balanceIconView.contentMode = .scaleAspectFit

        balanceLabel.translatesAutoresizingMaskIntoConstraints = false
        balanceLabel.text = "0"
        balanceLabel.font = AppFont.bold(size: 16)
        balanceLabel.textColor = Constants.darkTextColor

        view.insertSubview(headerBackgroundImageView, belowSubview: navBar)
        view.addSubview(headerView)
        headerView.addSubview(titleLabel)
        headerView.addSubview(balanceIconView)
        headerView.addSubview(balanceLabel)
    }

    private func configureProducts() {
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.backgroundColor = .clear
        collectionView.isScrollEnabled = false
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(WalletProductCell.self, forCellWithReuseIdentifier: WalletProductCell.reuseIdentifier)

        view.addSubview(collectionView)
    }

    private func configureLayout() {
        NSLayoutConstraint.activate([
            headerBackgroundImageView.topAnchor.constraint(equalTo: view.topAnchor),
            headerBackgroundImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            headerView.topAnchor.constraint(equalTo: navBar.bottomAnchor, constant: 38),
            headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            headerView.heightAnchor.constraint(equalToConstant: 83),

            titleLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 32),
            titleLabel.centerYAnchor.constraint(equalTo: headerView.centerYAnchor, constant: 12),

            balanceLabel.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -26),
            balanceLabel.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),

            balanceIconView.trailingAnchor.constraint(equalTo: balanceLabel.leadingAnchor, constant: -18),
            balanceIconView.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            balanceIconView.widthAnchor.constraint(equalToConstant: 54),
            balanceIconView.heightAnchor.constraint(equalToConstant: 54),

            collectionView.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 24),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -16),
        ])
    }

    @MainActor
    private func purchase(product: WalletProduct) async {
        AppLoading.show(
            in: view,
            message: NSLocalizedString("Processing...", comment: "Wallet purchase loading message"),
            autoDismiss: false
        )
        defer {
            AppLoading.dismiss(from: view)
        }

        do {
            let storeProduct = try await loadStoreProduct(productId: product.productId)
            let result = try await storeProduct.purchase()
            handlePurchaseResult(result, product: product)
        } catch {
            AppToast.show(message: NSLocalizedString("Failed to start purchase.", comment: "Purchase start failure toast"), in: view)
        }
    }

    @MainActor
    private func loadStoreProduct(productId: String) async throws -> StoreKit.Product {
        if let storeProduct = storeProducts[productId] {
            return storeProduct
        }

        guard let storeProduct = (try await StoreKit.Product.products(for: [productId])).first else {
            throw WalletPurchaseError.productNotFound
        }

        storeProducts[productId] = storeProduct
        return storeProduct
    }

    @MainActor
    private func handlePurchaseResult(_ result: StoreKit.Product.PurchaseResult, product: WalletProduct) {
        switch result {
        case .success(let verificationResult):
            switch verificationResult {
            case .verified(let transaction):
                let didSaveBalance = addBalance(for: product)
                Task {
                    await transaction.finish()
                }
                if didSaveBalance {
                    AppToast.show(message: NSLocalizedString("Purchase successful.", comment: "Purchase success toast"), in: view)
                }
            case .unverified:
                AppToast.show(message: NSLocalizedString("Purchase verification failed.", comment: "Purchase verification failure toast"), in: view)
            }
        case .pending:
            AppToast.show(message: NSLocalizedString("Purchase is pending.", comment: "Purchase pending toast"), in: view)
        case .userCancelled:
            break
        @unknown default:
            AppToast.show(message: NSLocalizedString("Purchase failed.", comment: "Purchase unknown failure toast"), in: view)
        }
    }

    private func addBalance(for product: WalletProduct) -> Bool {
        guard let walletKey = currentWalletKey() else {
            AppToast.show(message: NSLocalizedString("Failed to save balance.", comment: "Wallet balance save failure toast"), in: view)
            return false
        }
        guard let amount = Int(product.amount) else {
            AppToast.show(message: NSLocalizedString("Failed to save balance.", comment: "Wallet balance save failure toast"), in: view)
            return false
        }

        guard WalletKeychainStore.add(amount, for: walletKey) else {
            AppToast.show(message: NSLocalizedString("Failed to save balance.", comment: "Wallet balance save failure toast"), in: view)
            return false
        }

        updateBalance()
        return true
    }

    private func updateBalance() {
        guard let walletKey = currentWalletKey() else {
            balanceLabel.text = "0"
            return
        }

        balanceLabel.text = "\(WalletKeychainStore.balance(for: walletKey))"
    }

    private func currentWalletKey() -> String? {
        guard let userId = UserDefaults.standard.string(forKey: CurrentUserIdKey)?
            .trimmingCharacters(in: .whitespacesAndNewlines),
            !userId.isEmpty else {
            return nil
        }
        return "wallet.\(userId)"
    }
}

extension WalletViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        products.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: WalletProductCell.reuseIdentifier,
            for: indexPath
        ) as? WalletProductCell else {
            return UICollectionViewCell()
        }

        cell.configure(
            product: products[indexPath.item],
            isSelected: indexPath.item == selectedProductIndex,
            selectedColor: Constants.selectedColor
        )
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard guardRegisteredUser() else {
            return
        }

        if selectedProductIndex != indexPath.item {
            let oldIndexPath = IndexPath(item: selectedProductIndex, section: 0)
            selectedProductIndex = indexPath.item
            collectionView.reloadItems(at: [oldIndexPath, indexPath])
        }

        let product = products[indexPath.item]
        Task { [weak self] in
            await self?.purchase(product: product)
        }
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        let width = floor((collectionView.bounds.width - 28) / 3)
        return CGSize(width: width, height: 90)
    }
}

private extension WalletViewController {
    func guardRegisteredUser() -> Bool {
        guard let user = loadCurrentUser(), !isGuestUser(user) else {
            showLoginAlert()
            return false
        }
        return true
    }

    func loadCurrentUser() -> User? {
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

    func isGuestUser(_ user: User) -> Bool {
        if let guestUserId = UserDefaults.standard.string(forKey: GuestUserIdKey),
           guestUserId == user.id.uuidString {
            return true
        }

        return user.email?.lowercased().hasSuffix("@guest.campa") == true
    }

    func showLoginAlert() {
        guard presentedViewController == nil else {
            return
        }

        present(LoginAlertController(), animated: false)
    }
}

private struct WalletProduct {
    let productId: String
    let amount: String
    let price: String
}

private enum WalletPurchaseError: Error {
    case productNotFound
}

enum WalletKeychainStore {
    private static let service = "com.campa.wallet.amount"

    static func balance(for key: String) -> Int {
        integer(for: key)
    }

    static func add(_ amount: Int, for key: String) -> Bool {
        guard amount >= 0 else { return false }
        return setInteger(integer(for: key) + amount, for: key)
    }

    static func deduct(_ amount: Int, for key: String) -> Bool {
        guard amount >= 0 else { return false }
        let currentAmount = integer(for: key)
        guard currentAmount >= amount else { return false }
        return setInteger(currentAmount - amount, for: key)
    }

    static func integer(for key: String) -> Int {
        guard let value = string(for: key), let integer = Int(value) else {
            return 0
        }
        return integer
    }

    static func setInteger(_ value: Int, for key: String) -> Bool {
        setString("\(value)", for: key)
    }

    private static func string(for key: String) -> String? {
        var query = baseQuery(for: key)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess,
              let data = result as? Data else {
            return nil
        }
        return String(data: data, encoding: .utf8)
    }

    private static func setString(_ value: String, for key: String) -> Bool {
        guard let data = value.data(using: .utf8) else {
            return false
        }

        let query = baseQuery(for: key)
        let attributes: [String: Any] = [
            kSecValueData as String: data
        ]
        let updateStatus = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        if updateStatus == errSecSuccess {
            return true
        }

        guard updateStatus == errSecItemNotFound else {
            return false
        }

        var addQuery = query
        addQuery[kSecValueData as String] = data
        return SecItemAdd(addQuery as CFDictionary, nil) == errSecSuccess
    }

    private static func baseQuery(for key: String) -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
    }
}

private final class WalletProductCell: UICollectionViewCell {
    static let reuseIdentifier = "WalletProductCell"

    private let iconView = UIImageView()
    private let amountLabel = UILabel()
    private let priceLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)

        configureViews()
        configureLayout()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }

    func configure(product: WalletProduct, isSelected: Bool, selectedColor: UIColor) {
        contentView.backgroundColor = isSelected ? selectedColor : .white
        amountLabel.text = product.amount
        priceLabel.text = product.price
    }

    private func configureViews() {
        contentView.layer.cornerRadius = 12
        contentView.clipsToBounds = true

        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.image = UIImage(named: "vip_icon")
        iconView.contentMode = .scaleAspectFit

        amountLabel.translatesAutoresizingMaskIntoConstraints = false
        amountLabel.font = AppFont.medium(size: 15)
        amountLabel.textColor = UIColor(red: 0.28, green: 0.02, blue: 0.02, alpha: 1.0)
        amountLabel.textAlignment = .center

        priceLabel.translatesAutoresizingMaskIntoConstraints = false
        priceLabel.font = AppFont.medium(size: 10)
        priceLabel.textColor = .white
        priceLabel.textAlignment = .center
        priceLabel.backgroundColor = .black
        priceLabel.layer.cornerRadius = 10
        priceLabel.clipsToBounds = true

        contentView.addSubview(iconView)
        contentView.addSubview(amountLabel)
        contentView.addSubview(priceLabel)
    }

    private func configureLayout() {
        NSLayoutConstraint.activate([
            iconView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 11),
            iconView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 26),
            iconView.heightAnchor.constraint(equalToConstant: 20),

            amountLabel.topAnchor.constraint(equalTo: iconView.bottomAnchor, constant: 2),
            amountLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 6),
            amountLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -6),

            priceLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            priceLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10),
            priceLabel.widthAnchor.constraint(equalToConstant: 50),
            priceLabel.heightAnchor.constraint(equalToConstant: 20)
        ])
    }
}
