import UIKit

enum AppFont {
    static func regular(size: CGFloat) -> UIFont {
        font(named: "TimesNewRomanPSMT", size: size)
    }

    static func medium(size: CGFloat) -> UIFont {
        regular(size: size)
    }

    static func semibold(size: CGFloat) -> UIFont {
        bold(size: size)
    }

    static func bold(size: CGFloat) -> UIFont {
        font(named: "TimesNewRomanPS-BoldMT", size: size)
    }

    private static func font(named name: String, size: CGFloat) -> UIFont {
        UIFont(name: name, size: size) ?? .systemFont(ofSize: size)
    }
}
