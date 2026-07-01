import Foundation

enum UserRelationType: String {
    case follow
    case block
}

enum ChatConversationType: String {
    case `private`
    case group
}

enum ChatParticipantRole: String {
    case owner
    case member
}

enum ChatMessageType: String {
    case text
    case image
    case system
}

enum ChatMessageStatus: String {
    case sent
    case failed
}

enum ActivityStatus: String {
    case draft
    case published
    case ended
    case cancelled
}

enum ActivityParticipantRole: String {
    case owner
    case participant
}

enum ActivityParticipantStatus: String {
    case joined
    case cancelled
}
