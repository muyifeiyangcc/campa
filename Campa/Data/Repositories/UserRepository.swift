import CoreData
import Foundation

private enum BlockedFollowDirection: String {
    case sourceToTarget
    case targetToSource
}

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

        let now = Date()
        let user = User(context: context)
        user.id = UUID()
        user.nickname = nickname
        user.isCurrentUser = isCurrentUser
        user.createdAt = now
        user.updatedAt = now

        return saveAndReturn(user)
    }

    func createGuestCurrentUser() -> Result<User, PersistenceError> {
        clearCurrentUserFlag()

        let now = Date()
        let userId = UUID()
        let suffix = String(userId.uuidString.prefix(8))
        let user = User(context: context)
        user.id = userId
        user.email = "guest_\(suffix.lowercased())@guest.campa"
        user.passwordHash = nil
        user.nickname = "Guest \(suffix)"
        user.isCurrentUser = true
        user.createdAt = now
        user.updatedAt = now

        return saveAndReturn(user)
    }

    func activateUser(_ user: User) -> Result<User, PersistenceError> {
        clearCurrentUserFlag()
        user.isCurrentUser = true
        user.updatedAt = Date()
        return saveAndReturn(user)
    }

    func createRegisteredCurrentUser(
        email: String,
        passwordHash: String,
        nickname: String,
        birthday: Date?,
        location: String?,
        gender: String?,
        avatarLocalPath: String? = nil
    ) -> Result<User, PersistenceError> {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let trimmedNickname = nickname.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedEmail.isEmpty, !trimmedNickname.isEmpty else {
            return .failure(.invalidTitle)
        }
        guard !hasUser(email: trimmedEmail) else {
            return .failure(.duplicateRelation)
        }

        clearCurrentUserFlag()

        let now = Date()
        let user = User(context: context)
        user.id = UUID()
        user.email = trimmedEmail
        user.passwordHash = passwordHash
        user.nickname = trimmedNickname
        user.birthday = birthday
        user.location = location?.trimmingCharacters(in: .whitespacesAndNewlines)
        user.gender = gender
        user.avatarLocalPath = avatarLocalPath
        user.isCurrentUser = true
        user.createdAt = now
        user.updatedAt = now

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

    func fetchUser(id: UUID) -> Result<User, PersistenceError> {
        let request = User.fetchRequest()
        request.fetchLimit = 1
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)

        do {
            guard let user = try context.fetch(request).first else {
                return .failure(.missingCurrentUser)
            }
            return .success(user)
        } catch {
            return .failure(.coreDataSaveFailed)
        }
    }

    func login(email: String, passwordHash: String) -> Result<User, PersistenceError> {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !trimmedEmail.isEmpty, !passwordHash.isEmpty else {
            return .failure(.missingCurrentUser)
        }

        let request = User.fetchRequest()
        request.fetchLimit = 1
        request.predicate = NSPredicate(
            format: "email ==[c] %@ AND passwordHash == %@",
            trimmedEmail,
            passwordHash
        )

        do {
            guard let user = try context.fetch(request).first else {
                return .failure(.missingCurrentUser)
            }

            clearCurrentUserFlag()
            user.isCurrentUser = true
            user.updatedAt = Date()
            try context.save()
            return .success(user)
        } catch {
            return .failure(.coreDataSaveFailed)
        }
    }

    func deleteUser(email: String) -> Result<Void, PersistenceError> {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !trimmedEmail.isEmpty else {
            return .failure(.missingCurrentUser)
        }

        let request = User.fetchRequest()
        request.predicate = NSPredicate(format: "email ==[c] %@", trimmedEmail)

        do {
            let users = try context.fetch(request)
            guard !users.isEmpty else {
                return .failure(.missingCurrentUser)
            }

            users.forEach { context.delete($0) }
            try context.save()
            return .success(())
        } catch {
            context.rollback()
            return .failure(.coreDataSaveFailed)
        }
    }

    func updateUser(id: UUID, nickname: String, avatarLocalPath: String?) -> Result<User, PersistenceError> {
        let trimmedNickname = nickname.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedNickname.isEmpty else {
            return .failure(.invalidTitle)
        }

        switch fetchUser(id: id) {
        case .success(let user):
            user.nickname = trimmedNickname
            user.avatarLocalPath = avatarLocalPath
            user.updatedAt = Date()
            return saveAndReturn(user)
        case .failure(let error):
            return .failure(error)
        }
    }

    func updatePassword(email: String, passwordHash: String) -> Result<User, PersistenceError> {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !trimmedEmail.isEmpty, !passwordHash.isEmpty else {
            return .failure(.missingCurrentUser)
        }

        let request = User.fetchRequest()
        request.fetchLimit = 1
        request.predicate = NSPredicate(format: "email ==[c] %@", trimmedEmail)

        do {
            guard let user = try context.fetch(request).first else {
                return .failure(.missingCurrentUser)
            }

            user.passwordHash = passwordHash
            user.updatedAt = Date()
            return saveAndReturn(user)
        } catch {
            return .failure(.coreDataSaveFailed)
        }
    }

    func fetchFollowingUsers(for user: User) -> Result<[User], PersistenceError> {
        let request = UserRelation.fetchRequest()
        request.predicate = NSPredicate(
            format: "sourceUser == %@ AND type == %@",
            user,
            UserRelationType.follow.rawValue
        )
        request.sortDescriptors = [
            NSSortDescriptor(key: "createdAt", ascending: false)
        ]

        do {
            let relations = try context.fetch(request)
            let users = relations.compactMap { $0.targetUser }
            return .success(users)
        } catch {
            return .failure(.coreDataSaveFailed)
        }
    }

    func fetchFollowerUsers(for user: User) -> Result<[User], PersistenceError> {
        let request = UserRelation.fetchRequest()
        request.predicate = NSPredicate(
            format: "targetUser == %@ AND type == %@",
            user,
            UserRelationType.follow.rawValue
        )
        request.sortDescriptors = [
            NSSortDescriptor(key: "createdAt", ascending: false)
        ]

        do {
            let relations = try context.fetch(request)
            let users = relations.compactMap { $0.sourceUser }
            return .success(users)
        } catch {
            return .failure(.coreDataSaveFailed)
        }
    }

    func countFollowingUsers(for user: User) -> Result<Int, PersistenceError> {
        let request = UserRelation.fetchRequest()
        request.predicate = NSPredicate(
            format: "sourceUser == %@ AND type == %@",
            user,
            UserRelationType.follow.rawValue
        )

        do {
            return .success(try context.count(for: request))
        } catch {
            return .failure(.coreDataSaveFailed)
        }
    }

    func countFollowersUsers(for user: User) -> Result<Int, PersistenceError> {
        let request = UserRelation.fetchRequest()
        request.predicate = NSPredicate(
            format: "targetUser == %@ AND type == %@",
            user,
            UserRelationType.follow.rawValue
        )

        do {
            return .success(try context.count(for: request))
        } catch {
            return .failure(.coreDataSaveFailed)
        }
    }

    func fetchBlockedUsers(for user: User) -> Result<[User], PersistenceError> {
        let request = UserRelation.fetchRequest()
        request.predicate = NSPredicate(
            format: "sourceUser == %@ AND type == %@",
            user,
            UserRelationType.block.rawValue
        )
        request.sortDescriptors = [
            NSSortDescriptor(key: "createdAt", ascending: false)
        ]

        do {
            let relations = try context.fetch(request)
            let users = relations.compactMap { $0.targetUser }
            return .success(users)
        } catch {
            return .failure(.coreDataSaveFailed)
        }
    }

    func addRelation(from sourceUser: User, to targetUser: User, type: UserRelationType) -> Result<UserRelation, PersistenceError> {
        if case .success(true) = hasRelation(from: sourceUser, to: targetUser, type: type) {
            if type == .block {
                preserveFollowRelationsBeforeBlock(from: sourceUser, to: targetUser)
                removeFollowRelationsBetween(sourceUser, and: targetUser)
                NotificationCenter.default.post(name: .userBlockRelationDidChange, object: nil)
            }
            return .failure(.duplicateRelation)
        }

        let relation = UserRelation(context: context)
        relation.id = UUID()
        relation.sourceUser = sourceUser
        relation.targetUser = targetUser
        relation.type = type.rawValue
        relation.createdAt = Date()

        let result = saveAndReturn(relation)
        if case .success = result, type == .follow {
            NotificationCenter.default.post(name: .userFollowRelationDidChange, object: nil)
        }
        if case .success = result, type == .block {
            preserveFollowRelationsBeforeBlock(from: sourceUser, to: targetUser)
            removeFollowRelationsBetween(sourceUser, and: targetUser)
            NotificationCenter.default.post(name: .userBlockRelationDidChange, object: nil)
        }
        return result
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
                if type == .follow {
                    NotificationCenter.default.post(name: .userFollowRelationDidChange, object: nil)
                }
                if type == .block {
                    restoreFollowRelationsAfterUnblock(from: sourceUser, to: targetUser)
                    NotificationCenter.default.post(name: .userBlockRelationDidChange, object: nil)
                }
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

    private func removeFollowRelationsBetween(_ firstUser: User, and secondUser: User) {
        let request = UserRelation.fetchRequest()
        request.predicate = NSPredicate(
            format: "type == %@ AND ((sourceUser == %@ AND targetUser == %@) OR (sourceUser == %@ AND targetUser == %@))",
            UserRelationType.follow.rawValue,
            firstUser,
            secondUser,
            secondUser,
            firstUser
        )

        do {
            let relations = try context.fetch(request)
            guard !relations.isEmpty else {
                return
            }

            relations.forEach(context.delete)
            try context.save()
            NotificationCenter.default.post(name: .userFollowRelationDidChange, object: nil)
        } catch {
            context.rollback()
        }
    }

    private func preserveFollowRelationsBeforeBlock(from sourceUser: User, to targetUser: User) {
        let key = blockedFollowSnapshotKey(sourceUser: sourceUser, targetUser: targetUser)
        guard UserDefaults.standard.stringArray(forKey: key) == nil else {
            return
        }

        var directions: [String] = []
        if case .success(true) = hasRelation(from: sourceUser, to: targetUser, type: .follow) {
            directions.append(BlockedFollowDirection.sourceToTarget.rawValue)
        }
        if case .success(true) = hasRelation(from: targetUser, to: sourceUser, type: .follow) {
            directions.append(BlockedFollowDirection.targetToSource.rawValue)
        }

        UserDefaults.standard.set(directions, forKey: key)
    }

    private func restoreFollowRelationsAfterUnblock(from sourceUser: User, to targetUser: User) {
        let key = blockedFollowSnapshotKey(sourceUser: sourceUser, targetUser: targetUser)
        let directions = UserDefaults.standard.stringArray(forKey: key) ?? []
        UserDefaults.standard.removeObject(forKey: key)
        guard !directions.isEmpty else {
            return
        }

        let now = Date()
        var didRestore = false

        if directions.contains(BlockedFollowDirection.sourceToTarget.rawValue),
           case .success(false) = hasRelation(from: sourceUser, to: targetUser, type: .follow) {
            makeRelation(from: sourceUser, to: targetUser, type: .follow, createdAt: now)
            didRestore = true
        }

        if directions.contains(BlockedFollowDirection.targetToSource.rawValue),
           case .success(false) = hasRelation(from: targetUser, to: sourceUser, type: .follow) {
            makeRelation(from: targetUser, to: sourceUser, type: .follow, createdAt: now)
            didRestore = true
        }

        guard didRestore else {
            return
        }

        do {
            try context.save()
            NotificationCenter.default.post(name: .userFollowRelationDidChange, object: nil)
        } catch {
            context.rollback()
        }
    }

    private func makeRelation(from sourceUser: User, to targetUser: User, type: UserRelationType, createdAt: Date) {
        let relation = UserRelation(context: context)
        relation.id = UUID()
        relation.sourceUser = sourceUser
        relation.targetUser = targetUser
        relation.type = type.rawValue
        relation.createdAt = createdAt
    }

    private func blockedFollowSnapshotKey(sourceUser: User, targetUser: User) -> String {
        "blockedFollowSnapshot.\(sourceUser.id.uuidString).\(targetUser.id.uuidString)"
    }

    private func clearCurrentUserFlag() {
        let request = User.fetchRequest()
        request.predicate = NSPredicate(format: "isCurrentUser == YES")

        guard let users = try? context.fetch(request) else { return }
        let now = Date()
        users.forEach {
            $0.isCurrentUser = false
            $0.updatedAt = now
        }
    }

    private func hasUser(email: String) -> Bool {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !trimmedEmail.isEmpty else { return false }

        let request = User.fetchRequest()
        request.fetchLimit = 1
        request.predicate = NSPredicate(format: "email ==[c] %@", trimmedEmail)
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
