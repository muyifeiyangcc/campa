# Campa Offline CoreData Database Design

## Goal
Design a local-only CoreData database for Campa. The database supports users, private or group chats, follow and block relationships, posts with multiple images and comments, and activities with multiple images and participant information.

This design assumes no backend synchronization. All records are created, read, updated, and deleted locally on the device.

## Scope
- Add a CoreData persistence layer for local offline storage.
- Store image references as local file paths instead of binary data in CoreData.
- Keep the model suitable for UIKit + MVVM by exposing data through repositories or services rather than directly from view controllers.
- Support iOS 15.0+ and Swift 5.9+.

## Non-Goals
- No remote API synchronization.
- No conflict resolution, sync queue, remote IDs, or server status fields.
- No SwiftUI.
- No multi-device data merge.

## Architecture
The database should live under a new data layer, for example:

```text
Campa/Data/Persistence
- CoreDataStack.swift
- Campa.xcdatamodeld

Campa/Data/Repositories
- UserRepository.swift
- ChatRepository.swift
- PostRepository.swift
- ActivityRepository.swift
```

ViewModels call repositories. Repositories own CoreData fetches, saves, updates, and deletes. View controllers should not access `NSManagedObjectContext` directly.

## Entity Overview

```text
User
UserRelation
ChatConversation
ChatParticipant
ChatMessage
Post
PostImage
PostComment
Activity
ActivityImage
ActivityParticipant
```

All entities use `id: UUID`, `createdAt: Date`, and `updatedAt: Date` where updates are expected.

## User
Represents an app user stored locally.

```text
User
- id: UUID
- nickname: String
- avatarLocalPath: String?
- school: String?
- bio: String?
- gender: String?
- birthday: Date?
- isCurrentUser: Bool
- createdAt: Date
- updatedAt: Date
```

Relationships:
- `posts`: to-many `Post`, inverse `author`
- `activities`: to-many `Activity`, inverse `author`
- `messages`: to-many `ChatMessage`, inverse `sender`
- `comments`: to-many `PostComment`, inverse `author`

Notes:
- `isCurrentUser` marks the local signed-in profile.
- The first version should enforce only one current user in repository logic.

## UserRelation
Represents one user's relationship toward another user.

```text
UserRelation
- id: UUID
- type: String
- createdAt: Date
```

Valid `type` values:
- `follow`
- `block`

Relationships:
- `sourceUser`: to-one `User`
- `targetUser`: to-one `User`

Recommended uniqueness:
- A user should have at most one relation of the same `type` toward the same target user.
- Enforce this in repository logic before inserting a relation.

## Chat

### ChatConversation
Represents a chat thread.

```text
ChatConversation
- id: UUID
- type: String
- title: String?
- lastMessageText: String?
- lastMessageAt: Date?
- unreadCount: Int32
- createdAt: Date
- updatedAt: Date
```

Valid `type` values:
- `private`
- `group`

Relationships:
- `participants`: to-many `ChatParticipant`, inverse `conversation`
- `messages`: to-many `ChatMessage`, inverse `conversation`

### ChatParticipant
Connects users to conversations.

```text
ChatParticipant
- id: UUID
- role: String?
- joinedAt: Date
```

Valid `role` values:
- `owner`
- `member`

Relationships:
- `conversation`: to-one `ChatConversation`
- `user`: to-one `User`

### ChatMessage
Represents a message inside a conversation.

```text
ChatMessage
- id: UUID
- content: String?
- messageType: String
- imageLocalPath: String?
- sentAt: Date
- status: String
- createdAt: Date
```

Valid `messageType` values:
- `text`
- `image`
- `system`

Valid `status` values:
- `sent`
- `failed`

Relationships:
- `conversation`: to-one `ChatConversation`
- `sender`: to-one `User`

Rules:
- Text messages require non-empty `content`.
- Image messages require non-empty `imageLocalPath`.
- After inserting a message, update the parent conversation's `lastMessageText`, `lastMessageAt`, and `updatedAt`.

## Posts

### Post
Represents user-created content with a title, body, address, images, and comments.

```text
Post
- id: UUID
- title: String
- content: String
- addressText: String?
- latitude: Double
- longitude: Double
- likeCount: Int32
- commentCount: Int32
- createdAt: Date
- updatedAt: Date
```

Relationships:
- `author`: to-one `User`
- `images`: to-many `PostImage`, inverse `post`
- `comments`: to-many `PostComment`, inverse `post`

Rules:
- `title` and `content` should be validated before saving.
- `commentCount` is denormalized for fast list rendering and should be updated whenever comments are inserted or deleted.
- Use `0` latitude and longitude only when no coordinate is selected; repository or domain models should expose this as an optional location when needed.

### PostImage
Represents one image attached to a post.

```text
PostImage
- id: UUID
- localPath: String
- sortIndex: Int16
- createdAt: Date
```

Relationships:
- `post`: to-one `Post`

Rules:
- Store the actual image file under the app sandbox, such as `Documents/Images/Posts/`.
- Sort by `sortIndex` ascending.
- Delete image files when the related CoreData records are deleted.

### PostComment
Represents a post comment or reply.

```text
PostComment
- id: UUID
- content: String
- createdAt: Date
- updatedAt: Date
```

Relationships:
- `post`: to-one `Post`
- `author`: to-one `User`
- `parentComment`: optional to-one `PostComment`
- `replies`: to-many `PostComment`, inverse `parentComment`

Rules:
- A comment with no `parentComment` is a top-level comment.
- A comment with `parentComment` is a reply.

## Activities

### Activity
Represents an offline campus activity with title, content, location, images, schedule, and participants.

```text
Activity
- id: UUID
- title: String
- content: String
- addressText: String?
- latitude: Double
- longitude: Double
- startAt: Date?
- endAt: Date?
- maxParticipants: Int32
- status: String
- createdAt: Date
- updatedAt: Date
```

Valid `status` values:
- `draft`
- `published`
- `ended`
- `cancelled`

Relationships:
- `author`: to-one `User`
- `images`: to-many `ActivityImage`, inverse `activity`
- `participants`: to-many `ActivityParticipant`, inverse `activity`

Rules:
- `title` and `content` should be validated before saving.
- If both dates exist, `endAt` must not be earlier than `startAt`.
- `maxParticipants` can be `0` to mean unlimited.

### ActivityImage
Represents one image attached to an activity.

```text
ActivityImage
- id: UUID
- localPath: String
- sortIndex: Int16
- createdAt: Date
```

Relationships:
- `activity`: to-one `Activity`

Rules:
- Store the actual image file under the app sandbox, such as `Documents/Images/Activities/`.
- Sort by `sortIndex` ascending.
- Delete image files when the related CoreData records are deleted.

### ActivityParticipant
Represents a user's participation record for an activity.

```text
ActivityParticipant
- id: UUID
- role: String
- status: String
- joinedAt: Date
```

Valid `role` values:
- `owner`
- `participant`

Valid `status` values:
- `joined`
- `cancelled`

Relationships:
- `activity`: to-one `Activity`
- `user`: to-one `User`

Rules:
- Each user should have at most one participant record per activity.
- The activity author should also have an `owner` participant record.

## Delete Rules

Recommended CoreData delete rules:

```text
User -> Post: Deny
User -> Activity: Deny
User -> ChatMessage: Deny
User -> PostComment: Deny

Post -> PostImage: Cascade
Post -> PostComment: Cascade

Activity -> ActivityImage: Cascade
Activity -> ActivityParticipant: Cascade

ChatConversation -> ChatMessage: Cascade
ChatConversation -> ChatParticipant: Cascade

PostComment -> replies: Cascade
```

Use `Deny` for deleting users that still own important content. This avoids accidentally removing posts, activities, messages, or comments when a user profile is deleted. If the product later needs account deletion, implement it as an explicit cleanup flow in repository code.

## Indexes And Fetch Patterns

Recommended indexes:

```text
User.nickname
UserRelation.sourceUser + targetUser + type
ChatMessage.conversation + sentAt
Post.author + createdAt
PostComment.post + createdAt
Activity.startAt
ActivityParticipant.activity + user
```

Primary fetch patterns:
- Current user: fetch `User` where `isCurrentUser == true`.
- Home feed: fetch `Post` sorted by `createdAt DESC`.
- Following feed: fetch followed user IDs from `UserRelation`, then fetch their posts.
- Block filtering: exclude authors blocked by the current user.
- Conversation list: fetch `ChatConversation` sorted by `lastMessageAt DESC`.
- Message history: fetch `ChatMessage` by conversation sorted by `sentAt ASC`.
- Activity list: fetch `Activity` sorted by `startAt ASC`, then `createdAt DESC`.
- Activity participants: fetch `ActivityParticipant` by activity sorted by `joinedAt ASC`.

## Image Storage
CoreData stores only relative local file paths. The app stores image data in the sandbox.

Recommended folders:

```text
Documents/Images/Users/
Documents/Images/Posts/
Documents/Images/Activities/
Documents/Images/Messages/
```

Image deletion should be coordinated by repositories:
- Delete the CoreData image record.
- Delete the corresponding file from disk.
- If file deletion fails, log the error and keep the database operation consistent.

## Repository Responsibilities

`UserRepository`:
- Create and update users.
- Fetch current user.
- Follow, unfollow, block, and unblock users.
- Check whether one user follows or blocks another.

`ChatRepository`:
- Create private or group conversations.
- Add participants.
- Insert text or image messages.
- Fetch conversation list and message history.
- Update unread counts.

`PostRepository`:
- Create, edit, and delete posts.
- Add and remove post images.
- Add and delete comments.
- Fetch home, following, and user-specific feeds.
- Apply current user's block list to feed queries.

`ActivityRepository`:
- Create, edit, cancel, and delete activities.
- Add and remove activity images.
- Join or leave activities.
- Fetch activity lists and participant lists.

## Error Handling
Repositories should return `Result` for operations that can fail. Expected errors include:
- Missing current user.
- Invalid title or content.
- Invalid activity date range.
- Duplicate follow, block, conversation participant, or activity participant.
- Image file save or delete failure.
- CoreData save failure.

## Testing
Unit tests should use an in-memory CoreData store.

Recommended tests:
- Create and fetch current user.
- Follow and block relation uniqueness.
- Create a conversation and insert messages.
- Message insert updates conversation summary fields.
- Create a post with multiple ordered images.
- Add top-level and reply comments.
- Comment count updates correctly.
- Create an activity with multiple ordered images.
- Join and leave an activity.
- Blocked users are excluded from post feeds.

## Implementation Order
1. Add `CoreDataStack` with persistent and in-memory store support.
2. Add `Campa.xcdatamodeld` with the entities above.
3. Add domain enums for relation type, chat type, message type, message status, activity status, participant role, and participant status.
4. Add repositories with small focused APIs.
5. Add in-memory unit tests for repository behavior.
6. Wire repositories into ViewModels incrementally.

## Open Decisions
No implementation-blocking decisions remain. A future account deletion feature should define an explicit repository-level cleanup flow before changing user delete behavior.
