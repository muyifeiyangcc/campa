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
