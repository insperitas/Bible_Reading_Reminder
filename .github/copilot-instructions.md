# Bible Reading Reminder — Copilot Instructions

## Project Overview
A Bible reading reminder app for Android with a home screen widget. Built with Flutter, distributed via F-Droid.

## Stack
- **Flutter** (Dart) — cross-platform UI framework
- **home_widget** — Android/iOS home screen widget bridge
- **flutter_local_notifications** — local reminders, no Firebase
- **WorkManager / AlarmManager** — background scheduling (AOSP only)

## FOSS Compliance Rules (apply to every file and dependency)
- NO Firebase, FCM, Google Analytics, Crashlytics, or any `com.google.android.gms` dependency
- NO proprietary Google APIs — use AOSP-level APIs only
- All dependencies must be buildable from source and F-Droid compatible
- Use bundled or system fonts only — no Google Fonts
- If a package pulls in a Google Play Services transitive dependency, flag it and find an alternative

## Code Conventions
- Dart: follow `flutter_lints` rules
- Keep widget rendering logic separate from business logic (feature folders, not layer folders)
- Prefer `const` constructors wherever possible
- All user-facing strings must be externalized for future localization

## Android Widget Constraints
- Widget layouts use RemoteViews — no arbitrary Flutter widgets; only supported view types
- Data passed between Flutter app and widget via `home_widget` shared preferences bridge
- Minimum touch target: 44×44 dp
- Support dark mode and dynamic text sizes
