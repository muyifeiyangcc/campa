import UIKit

enum AppLoading {
    private enum Constants {
        static let overlayIdentifier = "appLoadingOverlay"
        static let panelSize: CGFloat = 112
        static let panelCornerRadius: CGFloat = 16
        static let fadeDuration: TimeInterval = 0.2
        static let autoDismissRange: ClosedRange<TimeInterval> = 1...3
    }

    static func show(
        in view: UIView,
        message: String = NSLocalizedString("Loading...", comment: "Loading dialog message"),
        autoDismiss: Bool = true,
        completion: (() -> Void)? = nil
    ) {
        guard Thread.isMainThread else {
            DispatchQueue.main.async {
                show(in: view, message: message, autoDismiss: autoDismiss, completion: completion)
            }
            return
        }

        dismiss(from: view, animated: false)

        let overlayView = makeOverlayView()
        let panelView = makePanelView()
        let indicatorView = makeIndicatorView()
        let messageLabel = makeMessageLabel(message: message)

        view.addSubview(overlayView)
        overlayView.addSubview(panelView)
        panelView.addSubview(indicatorView)
        panelView.addSubview(messageLabel)

        NSLayoutConstraint.activate([
            overlayView.topAnchor.constraint(equalTo: view.topAnchor),
            overlayView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            overlayView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            overlayView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            panelView.centerXAnchor.constraint(equalTo: overlayView.centerXAnchor),
            panelView.centerYAnchor.constraint(equalTo: overlayView.centerYAnchor),
            panelView.widthAnchor.constraint(equalToConstant: Constants.panelSize),
            panelView.heightAnchor.constraint(equalToConstant: Constants.panelSize),

            indicatorView.centerXAnchor.constraint(equalTo: panelView.centerXAnchor),
            indicatorView.topAnchor.constraint(equalTo: panelView.topAnchor, constant: 26),

            messageLabel.topAnchor.constraint(equalTo: indicatorView.bottomAnchor, constant: 14),
            messageLabel.leadingAnchor.constraint(equalTo: panelView.leadingAnchor, constant: 12),
            messageLabel.trailingAnchor.constraint(equalTo: panelView.trailingAnchor, constant: -12)
        ])

        indicatorView.startAnimating()
        UIView.animate(withDuration: Constants.fadeDuration) {
            overlayView.alpha = 1
        }

        guard autoDismiss else {
            return
        }

        let delay = TimeInterval.random(in: Constants.autoDismissRange)
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak overlayView] in
            guard let overlayView, overlayView.superview != nil else {
                return
            }

            remove(overlayView, animated: true, completion: completion)
        }
    }

    static func dismiss(from view: UIView, animated: Bool = true) {
        guard Thread.isMainThread else {
            DispatchQueue.main.async {
                dismiss(from: view, animated: animated)
            }
            return
        }

        view.subviews
            .filter { $0.accessibilityIdentifier == Constants.overlayIdentifier }
            .forEach { remove($0, animated: animated) }
    }
}

private extension AppLoading {
    static func makeOverlayView() -> UIView {
        let overlayView = UIView()
        overlayView.translatesAutoresizingMaskIntoConstraints = false
        overlayView.backgroundColor = UIColor.black.withAlphaComponent(0.12)
        overlayView.alpha = 0
        overlayView.accessibilityIdentifier = Constants.overlayIdentifier
        return overlayView
    }

    static func makePanelView() -> UIView {
        let panelView = UIView()
        panelView.translatesAutoresizingMaskIntoConstraints = false
        panelView.backgroundColor = UIColor.black.withAlphaComponent(0.8)
        panelView.layer.cornerRadius = Constants.panelCornerRadius
        panelView.layer.shadowColor = UIColor.black.cgColor
        panelView.layer.shadowOpacity = 0.12
        panelView.layer.shadowRadius = 12
        panelView.layer.shadowOffset = CGSize(width: 0, height: 6)
        return panelView
    }

    static func makeIndicatorView() -> UIActivityIndicatorView {
        let indicatorView = UIActivityIndicatorView(style: .medium)
        indicatorView.translatesAutoresizingMaskIntoConstraints = false
        indicatorView.color = UIColor.white
        return indicatorView
    }

    static func makeMessageLabel(message: String) -> UILabel {
        let messageLabel = UILabel()
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        messageLabel.text = message
        messageLabel.textColor = UIColor.white
        messageLabel.font = AppFont.medium(size: 14)
        messageLabel.textAlignment = .center
        messageLabel.numberOfLines = 2
        return messageLabel
    }

    static func remove(_ overlayView: UIView, animated: Bool, completion: (() -> Void)? = nil) {
        let animations = {
            overlayView.alpha = 0
        }
        let animationCompletion: (Bool) -> Void = { _ in
            overlayView.removeFromSuperview()
            completion?()
        }

        guard animated else {
            animations()
            animationCompletion(true)
            return
        }

        UIView.animate(
            withDuration: Constants.fadeDuration,
            animations: animations,
            completion: animationCompletion
        )
    }
}
