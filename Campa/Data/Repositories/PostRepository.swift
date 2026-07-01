import CoreData
import Foundation

final class PostRepository {
    private let context: NSManagedObjectContext

    init(context: NSManagedObjectContext = CoreDataStack.shared.viewContext) {
        self.context = context
    }

    func createPost(
        author: User,
        title: String,
        content: String,
        addressText: String?,
        imagePaths: [String],
        isBoosted: Bool = false
    ) -> Result<Post, PersistenceError> {
        guard !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return .failure(.invalidTitle)
        }
        guard !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return .failure(.invalidContent)
        }

        let now = Date()
        let post = Post(context: context)
        post.id = UUID()
        post.author = author
        post.title = title
        post.content = content
        post.addressText = addressText
        post.latitude = 0
        post.longitude = 0
        post.likeCount = isBoosted ? 300 : 0
        post.commentCount = 0
        post.createdAt = now
        post.updatedAt = now

        imagePaths.enumerated().forEach { index, path in
            let image = PostImage(context: context)
            image.id = UUID()
            image.post = post
            image.localPath = path
            image.sortIndex = Int16(index)
            image.createdAt = now
        }

        return saveAndReturn(post)
    }

    func addComment(to post: Post, author: User, content: String, parentComment: PostComment?) -> Result<PostComment, PersistenceError> {
        guard !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return .failure(.invalidContent)
        }

        let now = Date()
        let comment = PostComment(context: context)
        comment.id = UUID()
        comment.post = post
        comment.author = author
        comment.parentComment = parentComment
        comment.content = content
        comment.createdAt = now
        comment.updatedAt = now
        post.commentCount += 1
        post.updatedAt = now

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
            let posts = try context.fetch(request).sorted { lhs, rhs in
                let lhsIsHot = lhs.likeCount >= 300
                let rhsIsHot = rhs.likeCount >= 300
                if lhsIsHot != rhsIsHot {
                    return lhsIsHot
                }
                return lhs.createdAt > rhs.createdAt
            }
            return .success(posts)
        } catch {
            return .failure(.coreDataSaveFailed)
        }
    }

    func fetchPosts(for author: User) -> Result<[Post], PersistenceError> {
        let request = Post.fetchRequest()
        request.predicate = NSPredicate(format: "author == %@", author)
        request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]

        do {
            return .success(try context.fetch(request))
        } catch {
            return .failure(.coreDataSaveFailed)
        }
    }

    func countPosts(for author: User) -> Result<Int, PersistenceError> {
        let request = Post.fetchRequest()
        request.predicate = NSPredicate(format: "author == %@", author)

        do {
            return .success(try context.count(for: request))
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
