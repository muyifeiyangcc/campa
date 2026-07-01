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
