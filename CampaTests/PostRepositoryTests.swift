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

    override func tearDown() {
        postRepository = nil
        userRepository = nil
        stack = nil
        super.tearDown()
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
