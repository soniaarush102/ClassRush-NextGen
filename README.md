# CLASSRUSH

**A peer-to-peer mathematics discussion and collaboration platform for students of similar age groups.**

CLASSRUSH is being developed as a Flutter application, starting with Android and keeping the architecture ready for iOS and Windows.

## Product direction

- One common student account type; no teacher/student role split
- An open-room discovery model: students browse available maths discussion rooms and choose which ones to join
- Students can create a room, share its invite link/code, or join an open room without teacher approval
- Room listings can show topic, problem being discussed, participant count, and whether the room is open or full
- Live audio/video, participant controls, chat, and optional screen sharing
- Collaborative whiteboard with named live cursors and simultaneous writing
- Pen, highlighter, eraser, shapes, undo/redo, save, and export
- PDF viewing and annotation with synchronized pages
- Presentation and problem-sheet sharing
- Mathematics-focused writing and diagram tools
- Privacy-conscious profiles, room permissions, and community safety controls

## Core discussion-room layout

The main room is designed around:
- **70% workspace:** shared whiteboard, problem sheet, PDF, or presentation
- **30% participant rail:** video tiles for students in the discussion
- Named participant cursors, active-speaker state, and shared room controls

The goal is equal peer collaboration: everyone in a room can contribute to the discussion and shared workspace according to the room's permissions.

## Current implementation

- Material 3 Flutter app entry point
- Responsive dashboard shell
- Orange-and-white brand theme
- System-aware light and dark themes
- Initial navigation for Home, Discussion Rooms, Resources, and Settings (labels and destinations will evolve)
- Student-focused sign-in and account-creation UI with no teacher/student role selector

The current authentication screen is UI only. Authentication, age-band matching, video, whiteboard synchronization, and cloud persistence are not yet connected.

## Technology direction

- Flutter and Dart
- LiveKit for real-time audio/video
- Firebase Authentication, Cloud Firestore, and Cloud Storage
- Feature-first project structure

Students choose rooms themselves; CLASSRUSH does not automatically assign them to groups. Room discovery should show useful public room details without exposing personal contact information. Add age-appropriate privacy controls, reporting/blocking, room moderation tools, and safeguards for live participation.

Service credentials and environment-specific configuration must be supplied securely; never commit API secrets or private keys.

## Run locally

Install the Flutter SDK, then from the repository root:

```bash
flutter create --platforms=android,ios,windows .
flutter pub get
flutter run
```

To build an Android APK:

```bash
flutter build apk --release
```

## Development roadmap

1. Flutter platform scaffolding, app shell, navigation, and responsive UI
2. Single account flow and privacy-conscious student profiles
3. Open discussion-room discovery, room creation, and joining by choice
4. Live audio/video, participant rail, chat, and screen sharing
5. Realtime collaborative whiteboard and named cursors
6. Math tools, PDF annotation, and presentation sharing
7. Privacy/safety controls, persistence, QA, and release builds

## Repository

All new CLASSRUSH development belongs in this repository. The earlier repository is kept separate and untouched.
