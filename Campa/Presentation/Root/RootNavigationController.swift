import UIKit

final class RootNavigationController: UINavigationController {
    init() {
        super.init(rootViewController: AuthEntryViewController())
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        nil
    }
}
