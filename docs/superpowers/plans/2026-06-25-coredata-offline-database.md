# CoreData Offline Database Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build Campa's local-only CoreData storage for users, chats, follow/block relations, posts, comments, activities, images, and activity participants.

**Architecture:** Add a `Data` layer with a reusable `CoreDataStack`, generated CoreData model classes, small repository APIs, and in-memory unit tests. View controllers remain UIKit-only and do not access `NSManagedObjectContext`; ViewModels will consume repositories in later UI wiring work.

**Tech Stack:** Swift 5.9, iOS 15.0+, UIKit, CoreData, XCTest, Xcode project file.

---

## File Structure

- Create `Campa/Data/Persistence/CoreDataStack.swift`: owns `NSPersistentContainer`, persistent store loading, background contexts, and in-memory test containers.
- Create `Campa/Data/Persistence/Campa.xcdatamodeld/Campa.xcdatamodel/contents`: defines all CoreData entities, attributes, relationships, delete rules, indexes, and code generation settings.
- Create `Campa/Data/Models/PersistenceEnums.swift`: string-backed enums for relation type, chat type, message type, message status, activity status, activity role, and participant status.
- Create `Campa/Data/Repositories/PersistenceError.swift`: shared repository error enum.
- Create `Campa/Data/Repositories/UserRepository.swift`: user creation, current user handling, follow/block APIs.
- Create `Campa/Data/Repositories/ChatRepository.swift`: conversation creation, participant insertion, message insertion, conversation/message fetches.
- Create `Campa/Data/Repositories/PostRepository.swift`: post creation, image ordering, comments, feed fetches, blocked-user filtering.
- Create `Campa/Data/Repositories/ActivityRepository.swift`: activity creation, images, join/leave, participant fetches.
- Create `CampaTests/CoreDataStackTests.swift`: validates in-memory CoreData boot.
- Create `CampaTests/UserRepositoryTests.swift`: validates current user and relation uniqueness.
- Create `CampaTests/ChatRepositoryTests.swift`: validates conversations, participants, message insertion, conversation summary updates.
- Create `CampaTests/PostRepositoryTests.swift`: validates posts, ordered images, comments, counts, blocked filtering.
- Create `CampaTests/ActivityRepositoryTests.swift`: validates activities, ordered images, owner participant, join/leave behavior.
- Modify `Campa.xcodeproj/project.pbxproj`: add new source files, model file, and test files to the correct targets.

## Task 1: Add CoreData Stack And Model To The Project

**Files:**
- Create: `Campa/Data/Persistence/CoreDataStack.swift`
- Create: `Campa/Data/Persistence/Campa.xcdatamodeld/Campa.xcdatamodel/contents`
- Modify: `Campa.xcodeproj/project.pbxproj`
- Test: `CampaTests/CoreDataStackTests.swift`

- [ ] **Step 1: Write the failing CoreData stack test**

Create `CampaTests/CoreDataStackTests.swift`:

```swift
import CoreData
import XCTest
@testable import Campa

final class CoreDataStackTests: XCTestCase {
    func testInMemoryStackLoadsModelAndStore() throws {
        let stack = try CoreDataStack.makeInMemoryStack()
        let context = stack.viewContext

        XCTAssertEqual(context.concurrencyType, .mainQueueConcurrencyType)
        XCTAssertNotNil(stack.persistentStoreCoordinator.persistentStores.first)
        XCTAssertNotNil(NSEntityDescription.entity(forEntityName: "User", in: context))
        XCTAssertNotNil(NSEntityDescription.entity(forEntityName: "Post", in: context))
        XCTAssertNotNil(NSEntityDescription.entity(forEntityName: "Activity", in: context))
    }
}
```

- [ ] **Step 2: Run the test to verify it fails**

Run:

```bash
xcodebuild test -scheme Campa -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:CampaTests/CoreDataStackTests/testInMemoryStackLoadsModelAndStore
```

Expected: FAIL because `CoreDataStack` and the model do not exist yet.

- [ ] **Step 3: Add the CoreData model**

Create the `.xcdatamodeld` package and define these entities exactly:

```text
User(id UUID, nickname String, avatarLocalPath String optional, school String optional, bio String optional, gender String optional, birthday Date optional, isCurrentUser Boolean, createdAt Date, updatedAt Date)
UserRelation(id UUID, type String, createdAt Date)
ChatConversation(id UUID, type String, title String optional, lastMessageText String optional, lastMessageAt Date optional, unreadCount Integer 32, createdAt Date, updatedAt Date)
ChatParticipant(id UUID, role String optional, joinedAt Date)
ChatMessage(id UUID, content String optional, messageType String, imageLocalPath String optional, sentAt Date, status String, createdAt Date)
Post(id UUID, title String, content String, addressText String optional, latitude Double, longitude Double, likeCount Integer 32, commentCount Integer 32, createdAt Date, updatedAt Date)
PostImage(id UUID, localPath String, sortIndex Integer 16, createdAt Date)
PostComment(id UUID, content String, createdAt Date, updatedAt Date)
Activity(id UUID, title String, content String, addressText String optional, latitude Double, longitude Double, startAt Date optional, endAt Date optional, maxParticipants Integer 32, status String, createdAt Date, updatedAt Date)
ActivityImage(id UUID, localPath String, sortIndex Integer 16, createdAt Date)
ActivityParticipant(id UUID, role String, status String, joinedAt Date)
```

Add relationships:

```text
User.posts <-> Post.author, User.activities <-> Activity.author, User.messages <-> ChatMessage.sender, User.comments <-> PostComment.author
UserRelation.sourceUser -> User, UserRelation.targetUser -> User
ChatConversation.participants <-> ChatParticipant.conversation
ChatConversation.messages <-> ChatMessage.conversation
ChatParticipant.user -> User
Post.images <-> PostImage.post
Post.comments <-> PostComment.post
PostComment.parentComment <-> PostComment.replies
Activity.images <-> ActivityImage.activity
Activity.participants <-> ActivityParticipant.activity
ActivityParticipant.user -> User
```

Set delete rules:

```text
User.posts/activities/messages/comments: Deny
Post.images/comments: Cascade
Activity.images/participants: Cascade
ChatConversation.messages/participants: Cascade
PostComment.replies: Cascade
```

Use Class Definition code generation so Xcode generates `NSManagedObject` subclasses automatically.

- [ ] **Step 4: Add CoreDataStack implementation**

Create `Campa/Data/Persistence/CoreDataStack.swift`:

```swift
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
        persistentContainer = NSPersistentContainer(name: "Campa")

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
```

- [ ] **Step 5: Add files to Xcode project**

Modify `Campa.xcodeproj/project.pbxproj` so:

```text
CoreDataStack.swift is in the Campa target sources.
Campa.xcdatamodeld is in the Campa target resources/build files as an XCVersionGroup.
CoreDataStackTests.swift is in the CampaTests target sources.
```

- [ ] **Step 6: Run the CoreData stack test**

Run:

```bash
xcodebuild test -scheme Campa -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:CampaTests/CoreDataStackTests/testInMemoryStackLoadsModelAndStore
```

Expected: PASS.

- [ ] **Step 7: Commit**

```bash
git add Campa/Data/Persistence CampaTests/CoreDataStackTests.swift Campa.xcodeproj/project.pbxproj
git commit -m "Add CoreData stack and offline model"
```

## Task 2: Add Persistence Enums And Shared Errors

**Files:**
- Create: `Campa/Data/Models/PersistenceEnums.swift`
- Create: `Campa/Data/Repositories/PersistenceError.swift`
- Test: `CampaTests/PersistenceEnumsTests.swift`

- [ ] **Step 1: Write failing enum tests**

Create `CampaTests/PersistenceEnumsTests.swift`:

```swift
import XCTest
@testable import Campa

final class PersistenceEnumsTests: XCTestCase {
    func testRawValuesMatchCoreDataStorage() {
        XCTAssertEqual(UserRelationType.follow.rawValue, "follow")
        XCTAssertEqual(UserRelationType.block.rawValue, "block")
        XCTAssertEqual(ChatConversationType.private.rawValue, "private")
        XCTAssertEqual(ChatConversationType.group.rawValue, "group")
        XCTAssertEqual(ChatMessageType.text.rawValue, "text")
        XCTAssertEqual(ChatMessageType.image.rawValue, "image")
        XCTAssertEqual(ChatMessageStatus.sent.rawValue, "sent")
        XCTAssertEqual(ActivityStatus.published.rawValue, "published")
        XCTAssertEqual(ActivityParticipantRole.owner.rawValue, "owner")
        XCTAssertEqual(ActivityParticipantStatus.cancelled.rawValue, "cancelled")
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run:

```bash
xcodebuild test -scheme Campa -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:CampaTests/PersistenceEnumsTests/testRawValuesMatchCoreDataStorage
```

Expected: FAIL because the enums do not exist.

- [ ] **Step 3: Add enums**

Create `Campa/Data/Models/PersistenceEnums.swift`:

```swift
import Foundation

enum UserRelationType: String {
    case follow
    case block
}

enum ChatConversationType: String {
    case `private`
    case group
}

enum ChatParticipantRole: String {
    case owner
    case member
}

enum ChatMessageType: String {
    case text
    case image
    case system
}

enum ChatMessageStatus: String {
    case sent
    case failed
}

enum ActivityStatus: String {
    case draft
    case published
    case ended
    case cancelled
}

enum ActivityParticipantRole: String {
    case owner
    case participant
}

enum ActivityParticipantStatus: String {
    case joined
    case cancelled
}
```

- [ ] **Step 4: Add shared repository error**

Create `Campa/Data/Repositories/PersistenceError.swift`:

```swift
import Foundation

enum PersistenceError: Error, Equatable {
    case missingCurrentUser
    case invalidTitle
    case invalidContent
    case invalidActivityDateRange
    case duplicateRelation
    case duplicateParticipant
    case missingImagePath
    case coreDataSaveFailed
}
```

- [ ] **Step 5: Add files to Xcode project**

Modify `Campa.xcodeproj/project.pbxproj` so `PersistenceEnums.swift` and `PersistenceError.swift` are in the Campa target sources and `PersistenceEnumsTests.swift` is in the CampaTests target sources.

- [ ] **Step 6: Run enum tests**

Run:

```bash
xcodebuild test -scheme Campa -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:CampaTests/PersistenceEnumsTests/testRawValuesMatchCoreDataStorage
```

Expected: PASS.

- [ ] **Step 7: Commit**

```bash
git add Campa/Data/Models/PersistenceEnums.swift Campa/Data/Repositories/PersistenceError.swift CampaTests/PersistenceEnumsTests.swift Campa.xcodeproj/project.pbxproj
git commit -m "Add persistence enums and errors"
```

## Task 3: Add User Repository

**Files:**
- Create: `Campa/Data/Repositories/UserRepository.swift`
- Test: `CampaTests/UserRepositoryTests.swift`

- [ ] **Step 1: Write failing user repository tests**

Create `CampaTests/UserRepositoryTests.swift`:

```swift
import CoreData
import XCTest
@testable import Campa

final class UserRepositoryTests: XCTestCase {
    private var stack: CoreDataStack!
    private var repository: UserRepository!

    override func setUpWithError() throws {
        stack = try CoreDataStack.makeInMemoryStack()
        repository = UserRepository(context: stack.viewContext)
    }

    override func tearDown() {
        repository = nil
        stack = nil
        super.tearDown()
    }

    func testCreateCurrentUserReplacesExistingCurrentUser() throws {
        let first = try repository.createUser(nickname: "Ari", isCurrentUser: true).get()
        let second = try repository.createUser(nickname: "Mina", isCurrentUser: true).get()

        let current = try repository.fetchCurrentUser().get()

        XCTAssertEqual(current.id, second.id)
        XCTAssertFalse(first.isCurrentUser)
        XCTAssertTrue(second.isCurrentUser)
    }

    func testFollowAndBlockAreUniquePerTargetAndType() throws {
        let source = try repository.createUser(nickname: "Ari", isCurrentUser: true).get()
        let target = try repository.createUser(nickname: "Mina", isCurrentUser: false).get()

        XCTAssertNoThrow(try repository.addRelation(from: source, to: target, type: .follow).get())
        XCTAssertThrowsError(try repository.addRelation(from: source, to: target, type: .follow).get())
        XCTAssertNoThrow(try repository.addRelation(from: source, to: target, type: .block).get())
        XCTAssertTrue(try repository.hasRelation(from: source, to: target, type: .follow).get())
        XCTAssertTrue(try repository.hasRelation(from: source, to: target, type: .block).get())
    }
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run:

```bash
xcodebuild test -scheme Campa -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:CampaTests/UserRepositoryTests
```

Expected: FAIL because `UserRepository` does not exist.

- [ ] **Step 3: Add user repository implementation**

Create `Campa/Data/Repositories/UserRepository.swift`:

```swift
import CoreData
import Foundation

final class UserRepository {
    private let context: NSManagedObjectContext

    init(context: NSManagedObjectContext = CoreDataStack.shared.viewContext) {
        self.context = context
    }

    func createUser(nickname: String, isCurrentUser: Bool) -> Result<User, PersistenceError> {
        guard !nickname.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return .failure(.invalidTitle)
        }

        if isCurrentUser {
            clearCurrentUserFlag()
        }

        let user = User(context: context)
        user.id = UUID()
        user.nickname = nickname
        user.isCurrentUser = isCurrentUser
        user.createdAt = Date()
        user.updatedAt = user.createdAt

        return saveAndReturn(user)
    }

    func fetchCurrentUser() -> Result<User, PersistenceError> {
        let request = User.fetchRequest()
        request.fetchLimit = 1
        request.predicate = NSPredicate(format: "isCurrentUser == YES")

        do {
            guard let user = try context.fetch(request).first else {
                return .failure(.missingCurrentUser)
            }
            return .success(user)
        } catch {
            return .failure(.coreDataSaveFailed)
        }
    }

    func addRelation(from sourceUser: User, to targetUser: User, type: UserRelationType) -> Result<UserRelation, PersistenceError> {
        if case .success(true) = hasRelation(from: sourceUser, to: targetUser, type: type) {
            return .failure(.duplicateRelation)
        }

        let relation = UserRelation(context: context)
        relation.id = UUID()
        relation.sourceUser = sourceUser
        relation.targetUser = targetUser
        relation.type = type.rawValue
        relation.createdAt = Date()

        return saveAndReturn(relation)
    }

    func removeRelation(from sourceUser: User, to targetUser: User, type: UserRelationType) -> Result<Void, PersistenceError> {
        let request = UserRelation.fetchRequest()
        request.fetchLimit = 1
        request.predicate = NSPredicate(
            format: "sourceUser == %@ AND targetUser == %@ AND type == %@",
            sourceUser,
            targetUser,
            type.rawValue
        )

        do {
            if let relation = try context.fetch(request).first {
                context.delete(relation)
                try context.save()
            }
            return .success(())
        } catch {
            return .failure(.coreDataSaveFailed)
        }
    }

    func hasRelation(from sourceUser: User, to targetUser: User, type: UserRelationType) -> Result<Bool, PersistenceError> {
        let request = UserRelation.fetchRequest()
        request.fetchLimit = 1
        request.predicate = NSPredicate(
            format: "sourceUser == %@ AND targetUser == %@ AND type == %@",
            sourceUser,
            targetUser,
            type.rawValue
        )

        do {
            return .success(try context.count(for: request) > 0)
        } catch {
            return .failure(.coreDataSaveFailed)
        }
    }

    private func clearCurrentUserFlag() {
        let request = User.fetchRequest()
        request.predicate = NSPredicate(format: "isCurrentUser == YES")

        guard let users = try? context.fetch(request) else { return }
        users.forEach {
            $0.isCurrentUser = false
            $0.updatedAt = Date()
        }
    }

    private func saveAndReturn<T>(_ object: T) -> Result<T, PersistenceError> {
        do {
            try context.save()
            return .success(object)
        } catch {
            return .failure(.coreDataSaveFailed)
        }
    }
}
```

- [ ] **Step 4: Add files to Xcode project**

Modify `Campa.xcodeproj/project.pbxproj` so `UserRepository.swift` is in the Campa target sources and `UserRepositoryTests.swift` is in the CampaTests target sources.

- [ ] **Step 5: Run user repository tests**

Run:

```bash
xcodebuild test -scheme Campa -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:CampaTests/UserRepositoryTests
```

Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add Campa/Data/Repositories/UserRepository.swift CampaTests/UserRepositoryTests.swift Campa.xcodeproj/project.pbxproj
git commit -m "Add user repository"
```

## Task 4: Add Chat Repository

**Files:**
- Create: `Campa/Data/Repositories/ChatRepository.swift`
- Test: `CampaTests/ChatRepositoryTests.swift`

- [ ] **Step 1: Write failing chat tests**

Create `CampaTests/ChatRepositoryTests.swift`:

```swift
import XCTest
@testable import Campa

final class ChatRepositoryTests: XCTestCase {
    private var stack: CoreDataStack!
    private var userRepository: UserRepository!
    private var chatRepository: ChatRepository!

    override func setUpWithError() throws {
        stack = try CoreDataStack.makeInMemoryStack()
        userRepository = UserRepository(context: stack.viewContext)
        chatRepository = ChatRepository(context: stack.viewContext)
    }

    func testCreatePrivateConversationAndInsertMessage() throws {
        let current = try userRepository.createUser(nickname: "Ari", isCurrentUser: true).get()
        let friend = try userRepository.createUser(nickname: "Mina", isCurrentUser: false).get()
        let conversation = try chatRepository.createConversation(type: .private, title: nil, participants: [current, friend]).get()

        let message = try chatRepository.insertTextMessage("Hello", from: current, in: conversation).get()
        let messages = try chatRepository.fetchMessages(in: conversation).get()

        XCTAssertEqual(conversation.participants?.count, 2)
        XCTAssertEqual(message.content, "Hello")
        XCTAssertEqual(messages.map(\.content), ["Hello"])
        XCTAssertEqual(conversation.lastMessageText, "Hello")
        XCTAssertEqual(conversation.unreadCount, 0)
    }
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run:

```bash
xcodebuild test -scheme Campa -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:CampaTests/ChatRepositoryTests
```

Expected: FAIL because `ChatRepository` does not exist.

- [ ] **Step 3: Add chat repository implementation**

Create `Campa/Data/Repositories/ChatRepository.swift`:

```swift
import CoreData
import Foundation

final class ChatRepository {
    private let context: NSManagedObjectContext

    init(context: NSManagedObjectContext = CoreDataStack.shared.viewContext) {
        self.context = context
    }

    func createConversation(type: ChatConversationType, title: String?, participants: [User]) -> Result<ChatConversation, PersistenceError> {
        let conversation = ChatConversation(context: context)
        conversation.id = UUID()
        conversation.type = type.rawValue
        conversation.title = title
        conversation.unreadCount = 0
        conversation.createdAt = Date()
        conversation.updatedAt = conversation.createdAt

        for user in participants {
            let participant = ChatParticipant(context: context)
            participant.id = UUID()
            participant.user = user
            participant.conversation = conversation
            participant.role = ChatParticipantRole.member.rawValue
            participant.joinedAt = Date()
        }

        return saveAndReturn(conversation)
    }

    func insertTextMessage(_ text: String, from sender: User, in conversation: ChatConversation) -> Result<ChatMessage, PersistenceError> {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return .failure(.invalidContent)
        }

        let message = ChatMessage(context: context)
        message.id = UUID()
        message.content = text
        message.messageType = ChatMessageType.text.rawValue
        message.status = ChatMessageStatus.sent.rawValue
        message.sentAt = Date()
        message.createdAt = message.sentAt
        message.sender = sender
        message.conversation = conversation

        conversation.lastMessageText = text
        conversation.lastMessageAt = message.sentAt
        conversation.updatedAt = message.sentAt

        return saveAndReturn(message)
    }

    func fetchConversations() -> Result<[ChatConversation], PersistenceError> {
        let request = ChatConversation.fetchRequest()
        request.sortDescriptors = [
            NSSortDescriptor(key: "lastMessageAt", ascending: false),
            NSSortDescriptor(key: "createdAt", ascending: false)
        ]

        do {
            return .success(try context.fetch(request))
        } catch {
            return .failure(.coreDataSaveFailed)
        }
    }

    func fetchMessages(in conversation: ChatConversation) -> Result<[ChatMessage], PersistenceError> {
        let request = ChatMessage.fetchRequest()
        request.predicate = NSPredicate(format: "conversation == %@", conversation)
        request.sortDescriptors = [NSSortDescriptor(key: "sentAt", ascending: true)]

        do {
            return .success(try context.fetch(request))
        } catch {
            return .failure(.coreDataSaveFailed)
        }
    }

    private func saveAndReturn<T>(_ object: T) -> Result<T, PersistenceError> {
        do {
            try context.save()
            return .success(object)
        } catch {
            return .failure(.coreDataSaveFailed)
        }
    }
}
```

- [ ] **Step 4: Add files to Xcode project**

Modify `Campa.xcodeproj/project.pbxproj` so `ChatRepository.swift` is in the Campa target sources and `ChatRepositoryTests.swift` is in the CampaTests target sources.

- [ ] **Step 5: Run chat tests**

Run:

```bash
xcodebuild test -scheme Campa -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:CampaTests/ChatRepositoryTests
```

Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add Campa/Data/Repositories/ChatRepository.swift CampaTests/ChatRepositoryTests.swift Campa.xcodeproj/project.pbxproj
git commit -m "Add chat repository"
```

## Task 5: Add Post Repository

**Files:**
- Create: `Campa/Data/Repositories/PostRepository.swift`
- Test: `CampaTests/PostRepositoryTests.swift`

- [ ] **Step 1: Write failing post tests**

Create `CampaTests/PostRepositoryTests.swift`:

```swift
import XCTest
@testable import Campa

final class PostRepositoryTests: XCTestCase {
    private var stack: CoreDataStack!
    private var userRepository: UserRepository!
    private var postRepository: PostRepository!

    override func setUpWithError() throws {
        stack = try CoreDataStack.makeInMemoryStack()
        userRepository = UserRepository(context: stack.viewContext)
        postRepository = PostRepository(context: stack.viewContext)
    }

    func testCreatePostWithOrderedImagesAndComments() throws {
        let user = try userRepository.createUser(nickname: "Ari", isCurrentUser: true).get()
        let post = try postRepository.createPost(
            author: user,
            title: "Campus",
            content: "Sunny day",
            addressText: "Library",
            imagePaths: ["a.jpg", "b.jpg"]
        ).get()

        let comment = try postRepository.addComment(to: post, author: user, content: "Nice", parentComment: nil).get()
        let images = try postRepository.fetchImages(for: post).get()

        XCTAssertEqual(post.title, "Campus")
        XCTAssertEqual(post.commentCount, 1)
        XCTAssertEqual(comment.content, "Nice")
        XCTAssertEqual(images.map(\.localPath), ["a.jpg", "b.jpg"])
        XCTAssertEqual(images.map(\.sortIndex), [0, 1])
    }

    func testHomeFeedExcludesBlockedAuthors() throws {
        let current = try userRepository.createUser(nickname: "Ari", isCurrentUser: true).get()
        let blocked = try userRepository.createUser(nickname: "Mina", isCurrentUser: false).get()
        _ = try postRepository.createPost(author: current, title: "Mine", content: "Visible", addressText: nil, imagePaths: []).get()
        _ = try postRepository.createPost(author: blocked, title: "Blocked", content: "Hidden", addressText: nil, imagePaths: []).get()
        _ = try userRepository.addRelation(from: current, to: blocked, type: .block).get()

        let feed = try postRepository.fetchHomeFeed(for: current).get()

        XCTAssertEqual(feed.map(\.title), ["Mine"])
    }
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run:

```bash
xcodebuild test -scheme Campa -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:CampaTests/PostRepositoryTests
```

Expected: FAIL because `PostRepository` does not exist.

- [ ] **Step 3: Add post repository implementation**

Create `Campa/Data/Repositories/PostRepository.swift`:

```swift
import CoreData
import Foundation

final class PostRepository {
    private let context: NSManagedObjectContext

    init(context: NSManagedObjectContext = CoreDataStack.shared.viewContext) {
        self.context = context
    }

    func createPost(author: User, title: String, content: String, addressText: String?, imagePaths: [String]) -> Result<Post, PersistenceError> {
        guard !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return .failure(.invalidTitle)
        }
        guard !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return .failure(.invalidContent)
        }

        let post = Post(context: context)
        post.id = UUID()
        post.author = author
        post.title = title
        post.content = content
        post.addressText = addressText
        post.latitude = 0
        post.longitude = 0
        post.likeCount = 0
        post.commentCount = 0
        post.createdAt = Date()
        post.updatedAt = post.createdAt

        for (index, path) in imagePaths.enumerated() {
            let image = PostImage(context: context)
            image.id = UUID()
            image.post = post
            image.localPath = path
            image.sortIndex = Int16(index)
            image.createdAt = Date()
        }

        return saveAndReturn(post)
    }

    func addComment(to post: Post, author: User, content: String, parentComment: PostComment?) -> Result<PostComment, PersistenceError> {
        guard !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return .failure(.invalidContent)
        }

        let comment = PostComment(context: context)
        comment.id = UUID()
        comment.post = post
        comment.author = author
        comment.parentComment = parentComment
        comment.content = content
        comment.createdAt = Date()
        comment.updatedAt = comment.createdAt
        post.commentCount += 1
        post.updatedAt = Date()

        return saveAndReturn(comment)
    }

    func fetchImages(for post: Post) -> Result<[PostImage], PersistenceError> {
        let request = PostImage.fetchRequest()
        request.predicate = NSPredicate(format: "post == %@", post)
        request.sortDescriptors = [NSSortDescriptor(key: "sortIndex", ascending: true)]

        do {
            return .success(try context.fetch(request))
        } catch {
            return .failure(.coreDataSaveFailed)
        }
    }

    func fetchHomeFeed(for currentUser: User) -> Result<[Post], PersistenceError> {
        let blockedUsers = fetchBlockedUsers(for: currentUser)
        let request = Post.fetchRequest()
        if !blockedUsers.isEmpty {
            request.predicate = NSPredicate(format: "NOT (author IN %@)", blockedUsers)
        }
        request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]

        do {
            return .success(try context.fetch(request))
        } catch {
            return .failure(.coreDataSaveFailed)
        }
    }

    private func fetchBlockedUsers(for currentUser: User) -> [User] {
        let request = UserRelation.fetchRequest()
        request.predicate = NSPredicate(format: "sourceUser == %@ AND type == %@", currentUser, UserRelationType.block.rawValue)
        return (try? context.fetch(request).compactMap(\.targetUser)) ?? []
    }

    private func saveAndReturn<T>(_ object: T) -> Result<T, PersistenceError> {
        do {
            try context.save()
            return .success(object)
        } catch {
            return .failure(.coreDataSaveFailed)
        }
    }
}
```

- [ ] **Step 4: Add files to Xcode project**

Modify `Campa.xcodeproj/project.pbxproj` so `PostRepository.swift` is in the Campa target sources and `PostRepositoryTests.swift` is in the CampaTests target sources.

- [ ] **Step 5: Run post tests**

Run:

```bash
xcodebuild test -scheme Campa -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:CampaTests/PostRepositoryTests
```

Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add Campa/Data/Repositories/PostRepository.swift CampaTests/PostRepositoryTests.swift Campa.xcodeproj/project.pbxproj
git commit -m "Add post repository"
```

## Task 6: Add Activity Repository

**Files:**
- Create: `Campa/Data/Repositories/ActivityRepository.swift`
- Test: `CampaTests/ActivityRepositoryTests.swift`

- [ ] **Step 1: Write failing activity tests**

Create `CampaTests/ActivityRepositoryTests.swift`:

```swift
import XCTest
@testable import Campa

final class ActivityRepositoryTests: XCTestCase {
    private var stack: CoreDataStack!
    private var userRepository: UserRepository!
    private var activityRepository: ActivityRepository!

    override func setUpWithError() throws {
        stack = try CoreDataStack.makeInMemoryStack()
        userRepository = UserRepository(context: stack.viewContext)
        activityRepository = ActivityRepository(context: stack.viewContext)
    }

    func testCreateActivityAddsOrderedImagesAndOwnerParticipant() throws {
        let owner = try userRepository.createUser(nickname: "Ari", isCurrentUser: true).get()
        let activity = try activityRepository.createActivity(
            author: owner,
            title: "Market",
            content: "Campus market",
            addressText: "Main Gate",
            startAt: Date(timeIntervalSince1970: 100),
            endAt: Date(timeIntervalSince1970: 200),
            maxParticipants: 20,
            imagePaths: ["one.jpg", "two.jpg"]
        ).get()

        let images = try activityRepository.fetchImages(for: activity).get()
        let participants = try activityRepository.fetchParticipants(for: activity).get()

        XCTAssertEqual(activity.status, ActivityStatus.published.rawValue)
        XCTAssertEqual(images.map(\.localPath), ["one.jpg", "two.jpg"])
        XCTAssertEqual(participants.count, 1)
        XCTAssertEqual(participants.first?.role, ActivityParticipantRole.owner.rawValue)
    }

    func testJoinActivityIsUniquePerUser() throws {
        let owner = try userRepository.createUser(nickname: "Ari", isCurrentUser: true).get()
        let guest = try userRepository.createUser(nickname: "Mina", isCurrentUser: false).get()
        let activity = try activityRepository.createActivity(author: owner, title: "Market", content: "Campus market", addressText: nil, startAt: nil, endAt: nil, maxParticipants: 0, imagePaths: []).get()

        XCTAssertNoThrow(try activityRepository.join(activity: activity, user: guest).get())
        XCTAssertThrowsError(try activityRepository.join(activity: activity, user: guest).get())
    }
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run:

```bash
xcodebuild test -scheme Campa -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:CampaTests/ActivityRepositoryTests
```

Expected: FAIL because `ActivityRepository` does not exist.

- [ ] **Step 3: Add activity repository implementation**

Create `Campa/Data/Repositories/ActivityRepository.swift`:

```swift
import CoreData
import Foundation

final class ActivityRepository {
    private let context: NSManagedObjectContext

    init(context: NSManagedObjectContext = CoreDataStack.shared.viewContext) {
        self.context = context
    }

    func createActivity(author: User, title: String, content: String, addressText: String?, startAt: Date?, endAt: Date?, maxParticipants: Int32, imagePaths: [String]) -> Result<Activity, PersistenceError> {
        guard !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return .failure(.invalidTitle)
        }
        guard !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return .failure(.invalidContent)
        }
        if let startAt, let endAt, endAt < startAt {
            return .failure(.invalidActivityDateRange)
        }

        let activity = Activity(context: context)
        activity.id = UUID()
        activity.author = author
        activity.title = title
        activity.content = content
        activity.addressText = addressText
        activity.latitude = 0
        activity.longitude = 0
        activity.startAt = startAt
        activity.endAt = endAt
        activity.maxParticipants = maxParticipants
        activity.status = ActivityStatus.published.rawValue
        activity.createdAt = Date()
        activity.updatedAt = activity.createdAt

        for (index, path) in imagePaths.enumerated() {
            let image = ActivityImage(context: context)
            image.id = UUID()
            image.activity = activity
            image.localPath = path
            image.sortIndex = Int16(index)
            image.createdAt = Date()
        }

        let owner = ActivityParticipant(context: context)
        owner.id = UUID()
        owner.activity = activity
        owner.user = author
        owner.role = ActivityParticipantRole.owner.rawValue
        owner.status = ActivityParticipantStatus.joined.rawValue
        owner.joinedAt = Date()

        return saveAndReturn(activity)
    }

    func join(activity: Activity, user: User) -> Result<ActivityParticipant, PersistenceError> {
        if hasParticipant(activity: activity, user: user) {
            return .failure(.duplicateParticipant)
        }

        let participant = ActivityParticipant(context: context)
        participant.id = UUID()
        participant.activity = activity
        participant.user = user
        participant.role = ActivityParticipantRole.participant.rawValue
        participant.status = ActivityParticipantStatus.joined.rawValue
        participant.joinedAt = Date()

        return saveAndReturn(participant)
    }

    func fetchImages(for activity: Activity) -> Result<[ActivityImage], PersistenceError> {
        let request = ActivityImage.fetchRequest()
        request.predicate = NSPredicate(format: "activity == %@", activity)
        request.sortDescriptors = [NSSortDescriptor(key: "sortIndex", ascending: true)]

        do {
            return .success(try context.fetch(request))
        } catch {
            return .failure(.coreDataSaveFailed)
        }
    }

    func fetchParticipants(for activity: Activity) -> Result<[ActivityParticipant], PersistenceError> {
        let request = ActivityParticipant.fetchRequest()
        request.predicate = NSPredicate(format: "activity == %@", activity)
        request.sortDescriptors = [NSSortDescriptor(key: "joinedAt", ascending: true)]

        do {
            return .success(try context.fetch(request))
        } catch {
            return .failure(.coreDataSaveFailed)
        }
    }

    private func hasParticipant(activity: Activity, user: User) -> Bool {
        let request = ActivityParticipant.fetchRequest()
        request.fetchLimit = 1
        request.predicate = NSPredicate(format: "activity == %@ AND user == %@", activity, user)
        return ((try? context.count(for: request)) ?? 0) > 0
    }

    private func saveAndReturn<T>(_ object: T) -> Result<T, PersistenceError> {
        do {
            try context.save()
            return .success(object)
        } catch {
            return .failure(.coreDataSaveFailed)
        }
    }
}
```

- [ ] **Step 4: Add files to Xcode project**

Modify `Campa.xcodeproj/project.pbxproj` so `ActivityRepository.swift` is in the Campa target sources and `ActivityRepositoryTests.swift` is in the CampaTests target sources.

- [ ] **Step 5: Run activity tests**

Run:

```bash
xcodebuild test -scheme Campa -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:CampaTests/ActivityRepositoryTests
```

Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add Campa/Data/Repositories/ActivityRepository.swift CampaTests/ActivityRepositoryTests.swift Campa.xcodeproj/project.pbxproj
git commit -m "Add activity repository"
```

## Task 7: Run Full Verification

**Files:**
- Modify only files needed to fix compile or test issues discovered by verification.

- [ ] **Step 1: Run all unit tests**

Run:

```bash
xcodebuild test -scheme Campa -destination 'platform=iOS Simulator,name=iPhone 15'
```

Expected: BUILD SUCCEEDED and all tests pass.

- [ ] **Step 2: Inspect changed files**

Run:

```bash
git status --short
git diff --stat
```

Expected: only CoreData persistence, repository, test, and project-file changes are present.

- [ ] **Step 3: Commit verification fixes if any**

If verification required fixes, commit only those fixes:

```bash
git add Campa CampaTests Campa.xcodeproj/project.pbxproj
git commit -m "Fix CoreData repository verification issues"
```

Expected: no commit is needed if Task 1 through Task 6 already pass.

## Self-Review

- Spec coverage: The plan covers CoreData stack, model entities, local image paths, repositories, in-memory tests, user relations, chats, posts, comments, activities, participants, delete rules, and feed filtering.
- Scope: UI wiring is intentionally deferred because the spec focuses on the database and repository layer.
- Type consistency: Repository method names used in tests match the implementations shown in each task.
- Placeholder scan: No task uses placeholder instructions; each code task includes concrete files, commands, and expected results.
