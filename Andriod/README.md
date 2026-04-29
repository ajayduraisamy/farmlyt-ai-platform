# farmlyt_ai

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Cloud Translation Setup (Production-safe)

Do not hardcode API keys in Dart files.

1. Create a local file (not committed): `translation_config.local.json`
2. Use this format:

```json
{
  "GOOGLE_TRANSLATE_API_KEY": "YOUR_RESTRICTED_GOOGLE_TRANSLATE_KEY",
  "TRANSLATION_CLOUD_ONLY": "true",
  "TRANSLATION_PROXY_URL": ""
}
```

3. Run app:

```powershell
flutter run --dart-define-from-file=translation_config.local.json
```

4. Build release:

```powershell
flutter build apk --release --dart-define-from-file=translation_config.local.json
```

Recommended for production: use `TRANSLATION_PROXY_URL` instead of direct API key.
