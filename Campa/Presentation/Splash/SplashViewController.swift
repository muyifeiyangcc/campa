import UIKit

final class SplashViewController: UIViewController {
    private let viewModel: SplashViewModel
    private let logoView = UIImageView()
    private let titleLabel = UILabel()

    init(viewModel: SplashViewModel = SplashViewModel()) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        configureView()
        configureLogoView()
        configureTitleLabel()
        configureLayout()
    }

    private func configureView() {
        view.backgroundColor = UIColor(red: 0.98, green: 0.93, blue: 0.86, alpha: 1.0)
    }

    private func configureLogoView() {
        logoView.translatesAutoresizingMaskIntoConstraints = false
        logoView.layer.cornerRadius = 16
        logoView.image = UIImage(named: "logo")
    }

    private func configureTitleLabel() {
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = viewModel.title
        titleLabel.font = AppFont.semibold(size: 36)
        titleLabel.textColor = UIColor(red: 0.24, green: 0.15, blue: 0.10, alpha: 1.0)
        titleLabel.textAlignment = .center
        titleLabel.accessibilityIdentifier = "splashTitleLabel"
    }

    private func configureLayout() {
        view.addSubview(logoView)
        view.addSubview(titleLabel)

        NSLayoutConstraint.activate([
            logoView.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
            logoView.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor, constant: -120),
            logoView.widthAnchor.constraint(equalToConstant: 81),
            logoView.heightAnchor.constraint(equalTo: logoView.widthAnchor),


            titleLabel.topAnchor.constraint(equalTo: logoView.bottomAnchor, constant: 8),
            titleLabel.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
            titleLabel.leadingAnchor.constraint(greaterThanOrEqualTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 24),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -24)
        ])
    }
}
