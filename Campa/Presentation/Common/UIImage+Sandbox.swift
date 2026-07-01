import UIKit

extension UIImage {
    static func sandboxOrAssetImage(
        named storedPath: String?,
        documentsSubdirectory: String? = nil,
        fallbackName: String? = nil
    ) -> UIImage? {
        let value = storedPath?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !value.isEmpty else {
            return fallbackName.flatMap { UIImage(named: $0) } ?? UIImage(named: "muser")
        }

        let fileURL: URL?
        if value.hasPrefix("/") {
            fileURL = URL(fileURLWithPath: value)
        } else if let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            if let documentsSubdirectory {
                fileURL = documentsURL
                    .appendingPathComponent(documentsSubdirectory, isDirectory: true)
                    .appendingPathComponent(value)
            } else {
                fileURL = documentsURL.appendingPathComponent(value)
            }
        } else {
            fileURL = nil
        }

        if let fileURL,
           FileManager.default.fileExists(atPath: fileURL.path),
           let image = UIImage(contentsOfFile: fileURL.path) {
            return image
        }

        return UIImage(named: value) ?? fallbackName.flatMap { UIImage(named: $0) }
    }
}
