import CoreData
import Foundation

@objc(User)
final class User: NSManagedObject {
    @NSManaged var id: UUID
    @NSManaged var email: String?
    @NSManaged var passwordHash: String?
    @NSManaged var nickname: String
    @NSManaged var avatarLocalPath: String?
    @NSManaged var school: String?
    @NSManaged var location: String?
    @NSManaged var bio: String?
    @NSManaged var gender: String?
    @NSManaged var birthday: Date?
    @NSManaged var isCurrentUser: Bool
    @NSManaged var createdAt: Date
    @NSManaged var updatedAt: Date
    @NSManaged var posts: Set<Post>?
    @NSManaged var activities: Set<Activity>?
    @NSManaged var messages: Set<ChatMessage>?
    @NSManaged var comments: Set<PostComment>?
}

extension User {
    @nonobjc class func fetchRequest() -> NSFetchRequest<User> {
        NSFetchRequest<User>(entityName: "User")
    }
}

@objc(UserRelation)
final class UserRelation: NSManagedObject {
    @NSManaged var id: UUID
    @NSManaged var type: String
    @NSManaged var createdAt: Date
    @NSManaged var sourceUser: User?
    @NSManaged var targetUser: User?
}

extension UserRelation {
    @nonobjc class func fetchRequest() -> NSFetchRequest<UserRelation> {
        NSFetchRequest<UserRelation>(entityName: "UserRelation")
    }
}

@objc(ChatConversation)
final class ChatConversation: NSManagedObject {
    @NSManaged var id: UUID
    @NSManaged var type: String
    @NSManaged var title: String?
    @NSManaged var lastMessageText: String?
    @NSManaged var lastMessageAt: Date?
    @NSManaged var unreadCount: Int32
    @NSManaged var createdAt: Date
    @NSManaged var updatedAt: Date
    @NSManaged var participants: Set<ChatParticipant>?
    @NSManaged var messages: Set<ChatMessage>?
}

extension ChatConversation {
    @nonobjc class func fetchRequest() -> NSFetchRequest<ChatConversation> {
        NSFetchRequest<ChatConversation>(entityName: "ChatConversation")
    }
}

@objc(ChatParticipant)
final class ChatParticipant: NSManagedObject {
    @NSManaged var id: UUID
    @NSManaged var role: String?
    @NSManaged var joinedAt: Date
    @NSManaged var conversation: ChatConversation?
    @NSManaged var user: User?
}

extension ChatParticipant {
    @nonobjc class func fetchRequest() -> NSFetchRequest<ChatParticipant> {
        NSFetchRequest<ChatParticipant>(entityName: "ChatParticipant")
    }
}

@objc(ChatMessage)
final class ChatMessage: NSManagedObject {
    @NSManaged var id: UUID
    @NSManaged var content: String?
    @NSManaged var messageType: String
    @NSManaged var imageLocalPath: String?
    @NSManaged var sentAt: Date
    @NSManaged var status: String
    @NSManaged var createdAt: Date
    @NSManaged var conversation: ChatConversation?
    @NSManaged var sender: User?
}

extension ChatMessage {
    @nonobjc class func fetchRequest() -> NSFetchRequest<ChatMessage> {
        NSFetchRequest<ChatMessage>(entityName: "ChatMessage")
    }
}

@objc(Post)
final class Post: NSManagedObject {
    @NSManaged var id: UUID
    @NSManaged var title: String
    @NSManaged var content: String
    @NSManaged var addressText: String?
    @NSManaged var latitude: Double
    @NSManaged var longitude: Double
    @NSManaged var likeCount: Int32
    @NSManaged var commentCount: Int32
    @NSManaged var createdAt: Date
    @NSManaged var updatedAt: Date
    @NSManaged var author: User?
    @NSManaged var images: Set<PostImage>?
    @NSManaged var comments: Set<PostComment>?
}

extension Post {
    @nonobjc class func fetchRequest() -> NSFetchRequest<Post> {
        NSFetchRequest<Post>(entityName: "Post")
    }
}

@objc(PostImage)
final class PostImage: NSManagedObject {
    @NSManaged var id: UUID
    @NSManaged var localPath: String
    @NSManaged var sortIndex: Int16
    @NSManaged var createdAt: Date
    @NSManaged var post: Post?
}

extension PostImage {
    @nonobjc class func fetchRequest() -> NSFetchRequest<PostImage> {
        NSFetchRequest<PostImage>(entityName: "PostImage")
    }
}

@objc(PostComment)
final class PostComment: NSManagedObject {
    @NSManaged var id: UUID
    @NSManaged var content: String
    @NSManaged var createdAt: Date
    @NSManaged var updatedAt: Date
    @NSManaged var post: Post?
    @NSManaged var author: User?
    @NSManaged var parentComment: PostComment?
    @NSManaged var replies: Set<PostComment>?
}

extension PostComment {
    @nonobjc class func fetchRequest() -> NSFetchRequest<PostComment> {
        NSFetchRequest<PostComment>(entityName: "PostComment")
    }
}

@objc(Activity)
final class Activity: NSManagedObject {
    @NSManaged var id: UUID
    @NSManaged var title: String
    @NSManaged var content: String
    @NSManaged var addressText: String?
    @NSManaged var latitude: Double
    @NSManaged var longitude: Double
    @NSManaged var startAt: Date?
    @NSManaged var endAt: Date?
    @NSManaged var maxParticipants: Int32
    @NSManaged var status: String
    @NSManaged var createdAt: Date
    @NSManaged var updatedAt: Date
    @NSManaged var author: User?
    @NSManaged var images: Set<ActivityImage>?
    @NSManaged var participants: Set<ActivityParticipant>?
}

extension Activity {
    @nonobjc class func fetchRequest() -> NSFetchRequest<Activity> {
        NSFetchRequest<Activity>(entityName: "Activity")
    }
}

@objc(ActivityImage)
final class ActivityImage: NSManagedObject {
    @NSManaged var id: UUID
    @NSManaged var localPath: String
    @NSManaged var sortIndex: Int16
    @NSManaged var createdAt: Date
    @NSManaged var activity: Activity?
}

extension ActivityImage {
    @nonobjc class func fetchRequest() -> NSFetchRequest<ActivityImage> {
        NSFetchRequest<ActivityImage>(entityName: "ActivityImage")
    }
}

@objc(ActivityParticipant)
final class ActivityParticipant: NSManagedObject {
    @NSManaged var id: UUID
    @NSManaged var role: String
    @NSManaged var status: String
    @NSManaged var joinedAt: Date
    @NSManaged var activity: Activity?
    @NSManaged var user: User?
}

extension ActivityParticipant {
    @nonobjc class func fetchRequest() -> NSFetchRequest<ActivityParticipant> {
        NSFetchRequest<ActivityParticipant>(entityName: "ActivityParticipant")
    }
}
