# Firebase setup for CLASSRUSH

This repository includes FlutterFire packages, Firebase Android configuration, a Firestore room model/repository, security rules, and query indexes. The Android app initializes the configured Firebase project at startup.

## 1. Create the Firebase project

1. Open the Firebase Console: https://console.firebase.google.com/
2. Create a project named `classrush` (or another name you choose).
3. Add an Android app using the Android application ID from the generated Flutter Android project.
4. Enable **Authentication → Email/Password**.
5. Create a **Cloud Firestore** database. Start in production mode.

Do not share passwords, private keys, or service-account files in chat or commit them to GitHub.

## 2. Generate platform configuration

From the project root, after Flutter and Firebase CLI are installed:

```bash
dart pub global activate flutterfire_cli
flutterfire configure
```

Select the Firebase project and Android app. The command generates `lib/firebase_options.dart` and platform configuration. Keep generated private environment files out of public repositories if they contain credentials; Firebase client configuration is not a substitute for security rules.

## 3. Install packages

```bash
flutter pub get
```

## 4. Deploy Firestore rules and indexes

Install Firebase CLI, sign in, select the project, then deploy:

```bash
firebase use YOUR_FIREBASE_PROJECT_ID
firebase deploy --only firestore:rules,firestore:indexes
```

Profiles are private to their owner. Room discovery is available to signed-in users and is not filtered by age group. Open rooms do not have a fixed participant limit; participants are counted for display.

## 5. Current integration boundary

- `DiscussionRoomRepository` supports live open-room queries, room creation, joining, and leaving.
- Room creation and joining require an authenticated account and a profile document at `profiles/{uid}`.
- Profile fields: `displayName`, `createdAt`, `updatedAt`.
- Room membership count is updated with Firestore transactions; there is no configured maximum room size.
- The existing room screen still displays preview data until authentication/profile setup is wired into the app.

Before enabling public room discovery, add reporting, blocking, moderation, and a clear room safety process. Do not put email addresses, phone numbers, exact birth dates, or other contact details in room documents.
