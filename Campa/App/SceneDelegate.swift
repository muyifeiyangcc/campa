import UIKit

final class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let windowScene = scene as? UIWindowScene else {
            return
        }

        LocalDataSeeder.shared.seedIfNeeded()

        let window = UIWindow(windowScene: windowScene)
        if let userId = UserDefaults.standard.string(forKey: CurrentUserIdKey), userId.count > 0 {
            window.rootViewController = MainTabBarController()
        } else {
            window.rootViewController = UINavigationController(rootViewController: AuthEntryViewController())
        }
        window.makeKeyAndVisible()
        self.window = window
    }
}
