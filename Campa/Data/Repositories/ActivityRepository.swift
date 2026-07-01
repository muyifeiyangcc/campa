import CoreData
import Foundation

final class ActivityRepository {
    private let context: NSManagedObjectContext

    init(context: NSManagedObjectContext = CoreDataStack.shared.viewContext) {
        self.context = context
    }

    func createActivity(
        author: User,
        title: String,
        content: String,
        addressText: String?,
        startAt: Date?,
        endAt: Date?,
        maxParticipants: Int32,
        imagePaths: [String]
    ) -> Result<Activity, PersistenceError> {
        guard !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return .failure(.invalidTitle)
        }
        guard !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return .failure(.invalidContent)
        }
        if let startAt, let endAt, endAt < startAt {
            return .failure(.invalidActivityDateRange)
        }

        let now = Date()
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
        activity.createdAt = now
        activity.updatedAt = now

        imagePaths.enumerated().forEach { index, path in
            let image = ActivityImage(context: context)
            image.id = UUID()
            image.activity = activity
            image.localPath = path
            image.sortIndex = Int16(index)
            image.createdAt = now
        }

        let owner = ActivityParticipant(context: context)
        owner.id = UUID()
        owner.activity = activity
        owner.user = author
        owner.role = ActivityParticipantRole.owner.rawValue
        owner.status = ActivityParticipantStatus.joined.rawValue
        owner.joinedAt = now

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

    func fetchPublishedActivities() -> Result<[Activity], PersistenceError> {
        let request = Activity.fetchRequest()
        request.predicate = NSPredicate(format: "status == %@", ActivityStatus.published.rawValue)
        request.sortDescriptors = [
            NSSortDescriptor(key: "startAt", ascending: false),
            NSSortDescriptor(key: "createdAt", ascending: false)
        ]

        do {
            return .success(try context.fetch(request))
        } catch {
            return .failure(.coreDataSaveFailed)
        }
    }

    func fetchComments(forPostId postId: UUID) -> Result<[PostComment], PersistenceError> {
        let postRequest = Post.fetchRequest()
        postRequest.fetchLimit = 1
        postRequest.predicate = NSPredicate(format: "id == %@", postId as CVarArg)

        do {
            guard let post = try context.fetch(postRequest).first else {
                return .success([])
            }

            let request = PostComment.fetchRequest()
            request.predicate = NSPredicate(format: "post == %@", post)
            request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
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
