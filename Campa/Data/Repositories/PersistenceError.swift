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
