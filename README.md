# CLASSRUSH

**A collaborative online classroom for teachers and students.**

CLASSRUSH is being developed as a genuine Flutter application, starting with Android and keeping the architecture ready for iOS and Windows.

## Product direction

- Teacher and student accounts, profiles, and classroom management
- Create, join, and schedule live classes
- LiveKit-powered audio/video classrooms, participant controls, raise hand, chat, and screen sharing
- Collaborative infinite whiteboard with named live cursors and simultaneous drawing
- Pen, highlighter, eraser, shapes, undo/redo, permissions, save, and export
- PDF viewing and annotation with synchronized pages
- PPT/PPTX/PDF presentation and slide navigation
- Math-focused writing and diagram tools
- Secure persistence and classroom permissions using Firebase services
- Light and dark themes with CLASSRUSH orange-and-white branding

## Classroom layout

The primary teaching layout is designed around:
- **70% workspace:** whiteboard, slides, PDF, or shared screen
- **30% participant rail:** vertically stacked video tiles, with the teacher first
- Named participant cursors, active-speaker state, and classroom controls

## Current implementation

The first Flutter foundation is in place:
- Material 3 app entry point
- Responsive dashboard shell
- Orange-and-white brand theme
- System-aware light and dark themes
- Home, Classes, Recordings, and Settings navigation
- Create-class and join-class entry points (service integration is the next phase)

The dashboard is a starting implementation, not a claim that video, whiteboard synchronization, authentication, or cloud persistence are already connected.

## Technology direction

- Flutter and Dart
- LiveKit for real-time audio/video
- Firebase Authentication, Cloud Firestore, and Cloud Storage
- Feature-first project structure with separated app, theme, and feature layers

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
2. Authentication, user roles, profiles, and classroom lifecycle
3. LiveKit classroom: audio/video, screen share, participant rail, chat, and raise hand
4. Realtime collaborative whiteboard and named cursors
5. Math tools, PDF annotation, and presentation import
6. Firebase persistence, permissions, recording workflow, QA, and release builds

## Repository

All new CLASSRUSH development belongs in this repository. The earlier repository is kept separate and untouched.
