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

    override func tearDown() {
        chatRepository = nil
        userRepository = nil
        stack = nil
        super.tearDown()
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
