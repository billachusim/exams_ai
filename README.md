# ExamsAi (Android and iOS)

Flutter app for [ExamsAi](https://examsai.ng): an AI tutor, practice questions
with instant marking, and timed CBT mock exams for JAMB, WAEC and NECO.

It shares its backend with the website (repo `billachusim/examsai`, Supabase
project `qmshqibcpetahlmcacjw`). The API is documented in that repo at
`docs/BACKEND.md`. Accounts, limits, marking and Premium all live on the
server, so a student's Premium works on the web and in the app.

| | |
| --- | --- |
| Package | `examsai` |
| App ID / bundle ID | `com.techfaculty.examsai` |
| Apple team | `G5LYXH2XDA` |
| Store products | `examsai_day_pass` (1 day), `examsai_premium_monthly` (30 days) |

## Build

```sh
flutter pub get
dart run flutter_launcher_icons      # optional: icons are already in android/ and ios/
flutter analyze && flutter test
flutter build appbundle --release    # needs android/key.properties (Pet Care Card upload key)
flutter build ipa --release
```

Android signing reuses the Pet Care Card upload key: copy
`~/StudioProjects/Pet Care Card/android/key.properties` into `android/` and
point `storeFile` at the key. `key.properties` and `*.jks` are gitignored.

## Store setup

- Google Play: create the two products as one-time (consumable) in-app products.
- App Store: create them as non-renewing subscriptions.
- Give the Play service account access to this app, then add the store secrets
  listed in `docs/BACKEND.md` of the backend repo so purchases can be verified.

Account deletion is in Profile; the public deletion page is `/delete-account`
on the website.
