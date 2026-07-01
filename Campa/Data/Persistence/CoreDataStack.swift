import CoreData

final class CoreDataStack {
    static let shared = CoreDataStack()

    let persistentContainer: NSPersistentContainer

    var viewContext: NSManagedObjectContext {
        persistentContainer.viewContext
    }

    var persistentStoreCoordinator: NSPersistentStoreCoordinator {
        persistentContainer.persistentStoreCoordinator
    }

    init(inMemory: Bool = false) {
        let model = Self.makeManagedObjectModel()
        persistentContainer = NSPersistentContainer(name: "Campa", managedObjectModel: model)

        if inMemory {
            let description = NSPersistentStoreDescription()
            description.type = NSInMemoryStoreType
            persistentContainer.persistentStoreDescriptions = [description]
        }

        persistentContainer.loadPersistentStores { _, error in
            if let error {
                fatalError("Failed to load CoreData store: \(error)")
            }
        }

        viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        viewContext.automaticallyMergesChangesFromParent = true
    }

    static func makeInMemoryStack() throws -> CoreDataStack {
        CoreDataStack(inMemory: true)
    }

    func newBackgroundContext() -> NSManagedObjectContext {
        let context = persistentContainer.newBackgroundContext()
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return context
    }

    func saveContext() throws {
        guard viewContext.hasChanges else { return }
        try viewContext.save()
    }
}

// MARK: - Model Construction

private extension CoreDataStack {
    static func makeManagedObjectModel() -> NSManagedObjectModel {
        let model = NSManagedObjectModel()

        let user = entity("User", className: NSStringFromClass(User.self), properties: [
            attribute("id", .UUIDAttributeType),
            attribute("email", .stringAttributeType, optional: true),
            attribute("passwordHash", .stringAttributeType, optional: true),
            attribute("nickname", .stringAttributeType),
            attribute("avatarLocalPath", .stringAttributeType, optional: true),
            attribute("school", .stringAttributeType, optional: true),
            attribute("location", .stringAttributeType, optional: true),
            attribute("bio", .stringAttributeType, optional: true),
            attribute("gender", .stringAttributeType, optional: true),
            attribute("birthday", .dateAttributeType, optional: true),
            attribute("isCurrentUser", .booleanAttributeType, defaultValue: false),
            attribute("createdAt", .dateAttributeType),
            attribute("updatedAt", .dateAttributeType)
        ])

        let userRelation = entity("UserRelation", className: NSStringFromClass(UserRelation.self), properties: [
            attribute("id", .UUIDAttributeType),
            attribute("type", .stringAttributeType),
            attribute("createdAt", .dateAttributeType)
        ])

        let chatConversation = entity("ChatConversation", className: NSStringFromClass(ChatConversation.self), properties: [
            attribute("id", .UUIDAttributeType),
            attribute("type", .stringAttributeType),
            attribute("title", .stringAttributeType, optional: true),
            attribute("lastMessageText", .stringAttributeType, optional: true),
            attribute("lastMessageAt", .dateAttributeType, optional: true),
            attribute("unreadCount", .integer32AttributeType, defaultValue: 0),
            attribute("createdAt", .dateAttributeType),
            attribute("updatedAt", .dateAttributeType)
        ])

        let chatParticipant = entity("ChatParticipant", className: NSStringFromClass(ChatParticipant.self), properties: [
            attribute("id", .UUIDAttributeType),
            attribute("role", .stringAttributeType, optional: true),
            attribute("joinedAt", .dateAttributeType)
        ])

        let chatMessage = entity("ChatMessage", className: NSStringFromClass(ChatMessage.self), properties: [
            attribute("id", .UUIDAttributeType),
            attribute("content", .stringAttributeType, optional: true),
            attribute("messageType", .stringAttributeType),
            attribute("imageLocalPath", .stringAttributeType, optional: true),
            attribute("sentAt", .dateAttributeType),
            attribute("status", .stringAttributeType),
            attribute("createdAt", .dateAttributeType)
        ])

        let post = entity("Post", className: NSStringFromClass(Post.self), properties: [
            attribute("id", .UUIDAttributeType),
            attribute("title", .stringAttributeType),
            attribute("content", .stringAttributeType),
            attribute("addressText", .stringAttributeType, optional: true),
            attribute("latitude", .doubleAttributeType, defaultValue: 0),
            attribute("longitude", .doubleAttributeType, defaultValue: 0),
            attribute("likeCount", .integer32AttributeType, defaultValue: 0),
            attribute("commentCount", .integer32AttributeType, defaultValue: 0),
            attribute("createdAt", .dateAttributeType),
            attribute("updatedAt", .dateAttributeType)
        ])

        let postImage = entity("PostImage", className: NSStringFromClass(PostImage.self), properties: [
            attribute("id", .UUIDAttributeType),
            attribute("localPath", .stringAttributeType),
            attribute("sortIndex", .integer16AttributeType, defaultValue: 0),
            attribute("createdAt", .dateAttributeType)
        ])

        let postComment = entity("PostComment", className: NSStringFromClass(PostComment.self), properties: [
            attribute("id", .UUIDAttributeType),
            attribute("content", .stringAttributeType),
            attribute("createdAt", .dateAttributeType),
            attribute("updatedAt", .dateAttributeType)
        ])

        let activity = entity("Activity", className: NSStringFromClass(Activity.self), properties: [
            attribute("id", .UUIDAttributeType),
            attribute("title", .stringAttributeType),
            attribute("content", .stringAttributeType),
            attribute("addressText", .stringAttributeType, optional: true),
            attribute("latitude", .doubleAttributeType, defaultValue: 0),
            attribute("longitude", .doubleAttributeType, defaultValue: 0),
            attribute("startAt", .dateAttributeType, optional: true),
            attribute("endAt", .dateAttributeType, optional: true),
            attribute("maxParticipants", .integer32AttributeType, defaultValue: 0),
            attribute("status", .stringAttributeType),
            attribute("createdAt", .dateAttributeType),
            attribute("updatedAt", .dateAttributeType)
        ])

        let activityImage = entity("ActivityImage", className: NSStringFromClass(ActivityImage.self), properties: [
            attribute("id", .UUIDAttributeType),
            attribute("localPath", .stringAttributeType),
            attribute("sortIndex", .integer16AttributeType, defaultValue: 0),
            attribute("createdAt", .dateAttributeType)
        ])

        let activityParticipant = entity("ActivityParticipant", className: NSStringFromClass(ActivityParticipant.self), properties: [
            attribute("id", .UUIDAttributeType),
            attribute("role", .stringAttributeType),
            attribute("status", .stringAttributeType),
            attribute("joinedAt", .dateAttributeType)
        ])

        addRelationship("posts", from: user, to: post, inverseName: "author", toMany: true, deleteRule: .denyDeleteRule)
        addRelationship("activities", from: user, to: activity, inverseName: "author", toMany: true, deleteRule: .denyDeleteRule)
        addRelationship("messages", from: user, to: chatMessage, inverseName: "sender", toMany: true, deleteRule: .denyDeleteRule)
        addRelationship("comments", from: user, to: postComment, inverseName: "author", toMany: true, deleteRule: .denyDeleteRule)

        addOneWayRelationship("sourceUser", from: userRelation, to: user, deleteRule: .nullifyDeleteRule)
        addOneWayRelationship("targetUser", from: userRelation, to: user, deleteRule: .nullifyDeleteRule)

        addRelationship("participants", from: chatConversation, to: chatParticipant, inverseName: "conversation", toMany: true, deleteRule: .cascadeDeleteRule)
        addRelationship("messages", from: chatConversation, to: chatMessage, inverseName: "conversation", toMany: true, deleteRule: .cascadeDeleteRule)
        addOneWayRelationship("user", from: chatParticipant, to: user, deleteRule: .nullifyDeleteRule)

        addRelationship("images", from: post, to: postImage, inverseName: "post", toMany: true, deleteRule: .cascadeDeleteRule)
        addRelationship("comments", from: post, to: postComment, inverseName: "post", toMany: true, deleteRule: .cascadeDeleteRule)
        addRelationship("replies", from: postComment, to: postComment, inverseName: "parentComment", toMany: true, deleteRule: .cascadeDeleteRule)

        addRelationship("images", from: activity, to: activityImage, inverseName: "activity", toMany: true, deleteRule: .cascadeDeleteRule)
        addRelationship("participants", from: activity, to: activityParticipant, inverseName: "activity", toMany: true, deleteRule: .cascadeDeleteRule)
        addOneWayRelationship("user", from: activityParticipant, to: user, deleteRule: .nullifyDeleteRule)

        model.entities = [
            user,
            userRelation,
            chatConversation,
            chatParticipant,
            chatMessage,
            post,
            postImage,
            postComment,
            activity,
            activityImage,
            activityParticipant
        ]

        return model
    }

    static func entity(_ name: String, className: String, properties: [NSPropertyDescription]) -> NSEntityDescription {
        let entity = NSEntityDescription()
        entity.name = name
        entity.managedObjectClassName = className
        entity.properties = properties
        return entity
    }

    static func attribute(
        _ name: String,
        _ type: NSAttributeType,
        optional: Bool = false,
        defaultValue: Any? = nil
    ) -> NSAttributeDescription {
        let attribute = NSAttributeDescription()
        attribute.name = name
        attribute.attributeType = type
        attribute.isOptional = optional
        attribute.defaultValue = defaultValue
        return attribute
    }

    static func addRelationship(
        _ name: String,
        from source: NSEntityDescription,
        to destination: NSEntityDescription,
        inverseName: String,
        toMany: Bool,
        deleteRule: NSDeleteRule
    ) {
        let forwardRelationship = relationship(name, destination: destination, toMany: toMany, deleteRule: deleteRule)
        let inverse = relationship(inverseName, destination: source, toMany: false, deleteRule: .nullifyDeleteRule)
        forwardRelationship.inverseRelationship = inverse
        inverse.inverseRelationship = forwardRelationship
        source.properties.append(forwardRelationship)
        destination.properties.append(inverse)
    }

    static func addOneWayRelationship(
        _ name: String,
        from source: NSEntityDescription,
        to destination: NSEntityDescription,
        deleteRule: NSDeleteRule
    ) {
        source.properties.append(relationship(name, destination: destination, toMany: false, deleteRule: deleteRule))
    }

    static func relationship(
        _ name: String,
        destination: NSEntityDescription,
        toMany: Bool,
        deleteRule: NSDeleteRule
    ) -> NSRelationshipDescription {
        let relationship = NSRelationshipDescription()
        relationship.name = name
        relationship.destinationEntity = destination
        relationship.isOptional = !toMany
        relationship.minCount = 0
        relationship.maxCount = toMany ? 0 : 1
        relationship.deleteRule = deleteRule
        return relationship
    }
}
