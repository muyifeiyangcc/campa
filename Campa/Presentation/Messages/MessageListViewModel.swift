import UIKit

final class MessageListViewModel {
    let title = NSLocalizedString("Message", comment: "Message list screen title")
}

struct MessageListItem {
    let name: String
    let preview: String
    let time: String
    let unreadCount: Int?
    let avatarImage: UIImage?

    init(
        name: String,
        preview: String,
        time: String,
        unreadCount: Int?,
        avatarImage: UIImage? = nil
    ) {
        self.name = name
        self.preview = preview
        self.time = time
        self.unreadCount = unreadCount
        self.avatarImage = avatarImage
    }
}
