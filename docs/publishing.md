# Publishing EngiSteps

This is a focused first release of Circuit Fundamentals plus the engineering
workbench. It has not been submitted to an app store or deployed publicly.

## Build and test

```sh
flutter analyze
flutter test
flutter build web --release
flutter build apk --debug
```

The web artifact is `build/web`. The Android installable test artifact is
`build/app/outputs/flutter-apk/app-debug.apk`. A debug APK is for testing, not
Google Play submission.

The learning tests cover authored answer values, numerical tolerance, unit and
method feedback, assisted versus independent completion, progress restoration,
serialized writes, malformed records, narrow/wide layouts with enlarged text,
light/dark themes, and the first-example-to-practice navigation flow. Existing
calculator and persistence regression tests remain in the suite.

## Android upload signing

Release builds no longer silently use the debug key. A missing upload keystore
configuration stops `flutter build appbundle --release` with an actionable error.

1. Choose and confirm the permanent application ID before your first submission.
   The existing ID `EngiSteps.com.engisteps` is preserved to avoid accidentally
   changing the identity of any existing installation or listing.
2. Create or locate the upload keystore you intend to keep. Follow Flutter's
   [Android release instructions](https://docs.flutter.dev/deployment/android).
3. Copy `android/key.properties.example` to `android/key.properties`. Fill all four
   properties locally. `storeFile` is relative to `android/` or an absolute path;
   use forward slashes on Windows. Never put passwords or keystore files in Git.
4. Run `flutter build appbundle --release`. The expected artifact is
   `build/app/outputs/bundle/release/app-release.aab`.
5. Keep the upload key and credentials backed up securely. They are not generated
   or managed by this change.

See Google's [app signing documentation](https://developer.android.com/studio/publish/app-signing)
for the distinction between the upload key and app signing key.

## Remaining owner decisions and submission work

- Publisher account, permanent application identity, support email and public
  privacy URL. Complete `docs/privacy-notice.md` with your actual details.
- Store disclosures, intended age audience, content rating and distribution
  countries in the chosen store. Answer for the final packaged app and any services
  added before submission; no store questionnaire has been filled out here.
- Actual phone/tablet screenshots and store artwork. The app icon and listing
  copy are provided in `docs/store-icon.png` and `docs/store-listing.md`.
- Install on a physical Android device and test the keyboard, system Back,
  offline use, app restart, notes, copied working and font enlargement. A build
  alone does not verify these device behaviors.
- Run a small student pilot and have a course instructor review the explanations.
  The numerical answers are tested; learning effectiveness has not been measured.
- For iOS: use macOS/Xcode, configure your Apple developer team and signing, then
  archive and test on iOS. The iOS build is not verified on this Windows machine.

## Web publishing

Publish the contents of `build/web` to your selected static hosting provider over
HTTPS. The app uses hash routes. If hosting under a subdirectory, build with
`flutter build web --base-href /your-path/`. Verify fresh-load and reload behavior
at the public URL before sharing. Browser storage is tied to that origin, so
changing domains does not transfer local learning progress or notes.

The mobile app's offline behavior should not be used to promise reliable offline
web loading: first load requires network access and browser caching may vary.

## Release scope

Version remains `1.0.0+1` in `pubspec.yaml`. Before uploading, ensure the build
number exceeds any already uploaded build. No package identity, signing key,
publisher account or production domain was invented for this release.
