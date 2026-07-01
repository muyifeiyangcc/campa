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

    func testCreateRegisteredCurrentUserPersistsSignUpAndProfileFields() throws {
        let birthday = try XCTUnwrap(Calendar(identifier: .gregorian).date(from: DateComponents(year: 2003, month: 1, day: 1)))

        let user = try repository.createRegisteredCurrentUser(
            email: "ari@example.com",
            passwordHash: "hashed-password",
            nickname: "Ari",
            birthday: birthday,
            location: "Los Angeles",
            gender: "male"
        ).get()

        XCTAssertEqual(user.email, "ari@example.com")
        XCTAssertEqual(user.passwordHash, "hashed-password")
        XCTAssertEqual(user.nickname, "Ari")
        XCTAssertEqual(user.birthday, birthday)
        XCTAssertEqual(user.location, "Los Angeles")
        XCTAssertEqual(user.gender, "male")
        XCTAssertTrue(user.isCurrentUser)
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
