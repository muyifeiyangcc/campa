import UIKit

enum AppToast {
    enum VerticalRelation {
        case above(NSLayoutYAxisAnchor, spacing: CGFloat)
        case below(NSLayoutYAxisAnchor, spacing: CGFloat)
        case centered
    }

    private enum Constants {
        static let height: CGFloat = 36
        static let cornerRadius: CGFloat = 18
        static let horizontalInset: CGFloat = 24
        static let contentHorizontalInset: CGFloat = 24
        static let fadeDuration: TimeInterval = 0.2
        static let displayDuration: TimeInterval = 1.4
    }

    static func show(
        message: String,
        in view: UIView,
        relation: VerticalRelation = .centered,
        minWidth: CGFloat = 190,
        accessibilityIdentifier: String = "appToastLabel"
    ) {
        view.subviews
            .filter { $0.accessibilityIdentifier == accessibilityIdentifier }
            .forEach { $0.removeFromSuperview() }

        let toastLabel = AppToastLabel(contentInset: UIEdgeInsets(
            top: 0,
            left: Constants.contentHorizontalInset,
            bottom: 0,
            right: Constants.contentHorizontalInset
        ))
        toastLabel.translatesAutoresizingMaskIntoConstraints = false
        toastLabel.text = message
        toastLabel.textColor = .white
        toastLabel.font = AppFont.medium(size: 13)
        toastLabel.textAlignment = .center
        toastLabel.backgroundColor = UIColor.black.withAlphaComponent(0.72)
        toastLabel.layer.cornerRadius = Constants.cornerRadius
        toastLabel.clipsToBounds = true
        toastLabel.alpha = 0
        toastLabel.accessibilityIdentifier = accessibilityIdentifier

        view.addSubview(toastLabel)

        var constraints = [
            toastLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            toastLabel.heightAnchor.constraint(equalToConstant: Constants.height),
            toastLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: minWidth),
            toastLabel.leadingAnchor.constraint(greaterThanOrEqualTo: view.safeAreaLayoutGuide.leadingAnchor, constant: Constants.horizontalInset),
            toastLabel.trailingAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -Constants.horizontalInset)
        ]

        switch relation {
        case .above(let anchor, let spacing):
            constraints.append(toastLabel.bottomAnchor.constraint(equalTo: anchor, constant: -spacing))
        case .below(let anchor, let spacing):
            constraints.append(toastLabel.topAnchor.constraint(equalTo: anchor, constant: spacing))
        case .centered:
            constraints.append(toastLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor))
        }

        NSLayoutConstraint.activate(constraints)

        UIView.animate(withDuration: Constants.fadeDuration, animations: {
            toastLabel.alpha = 1
        }, completion: { _ in
            UIView.animate(
                withDuration: Constants.fadeDuration,
                delay: Constants.displayDuration,
                options: [],
                animations: {
                    toastLabel.alpha = 0
                },
                completion: { _ in
                    toastLabel.removeFromSuperview()
                }
            )
        })
    }
}

private final class AppToastLabel: UILabel {
    private let contentInset: UIEdgeInsets

    init(contentInset: UIEdgeInsets) {
        self.contentInset = contentInset
        super.init(frame: .zero)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }

    override func drawText(in rect: CGRect) {
        super.drawText(in: rect.inset(by: contentInset))
    }

    override var intrinsicContentSize: CGSize {
        let size = super.intrinsicContentSize
        return CGSize(
            width: size.width + contentInset.left + contentInset.right,
            height: size.height + contentInset.top + contentInset.bottom
        )
    }
}
