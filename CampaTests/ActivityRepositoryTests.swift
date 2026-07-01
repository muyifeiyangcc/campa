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

    override func tearDown() {
        activityRepository = nil
        userRepository = nil
        stack = nil
        super.tearDown()
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
