# Kombucha Making Toolkit

## Ads during development

Android and iOS use Google's sample AdMob app IDs by default. Debug builds use Google's platform-specific test banner units unless ad unit IDs are supplied. These IDs do not earn revenue.

```sh
flutter run
```

## Ads for a release

Create an AdMob app ID and two banner ad unit IDs for each platform. For Android, supply the app ID and both units when building:

```sh
flutter build appbundle --release \
  --dart-define=APPLICATION_ID=ca-app-pub-XXXXXXXXXXXXXXXX~YYYYYYYYYY \
  --dart-define=PAGE_BOTTOM_AD_ID=ca-app-pub-XXXXXXXXXXXXXXXX/BBBBBBBBBB \
  --dart-define=AD_BANNER_DRAWER_ID=ca-app-pub-XXXXXXXXXXXXXXXX/DDDDDDDDDD
```

For iOS, replace the sample `GADApplicationIdentifier` in `ios/Runner/Info.plist` with the iOS app ID, then supply the two iOS ad unit IDs with the same `--dart-define` names. Release builds without ad unit IDs do not request ads. Use test ads or test devices while developing with real ad units.

Before publishing, configure the appropriate consent message in AdMob Privacy & messaging. The app checks consent before requesting ads and shows a privacy options entry point when required. Complete the publisher details and app-store disclosures in `PRIVACY_POLICY.md`.
