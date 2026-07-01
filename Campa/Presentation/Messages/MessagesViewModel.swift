import UIKit

final class MessagesViewModel {
    let title = NSLocalizedString("Message", comment: "Messages screen title")
    let inputPlaceholder = NSLocalizedString("Type message", comment: "Message input placeholder")
}

struct MessageBubble {
    let text: String
    let isOutgoing: Bool
    let avatarImage: UIImage?
}
