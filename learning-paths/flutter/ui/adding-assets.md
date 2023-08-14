# Intro

Flutter apps can include both code and assets (sometimes called resources). Common types of assets include:
- static data (JSON files)
- configuration files
- icons and images (JPEG, WebP, GIF, animated WebP/GIF, PNG, BMP, and WBMP)

# Specifying assets

The [pubspec.yaml](https://dart.dev/tools/pub/pubspec) file is used to identify the required assets.

To include all assets under a directory, specify the directory name with the `/` character at the end:

```yaml
flutter:
  assets:
  	- assets/my_icon.png
    - directory/
    - directory/subdirectory/
```

# Loading assets

Access its assets through an [AssetBundle](https://api.flutter.dev/flutter/services/AssetBundle-class.html) object.

The two main methods on an asset bundle allow you to load out of the bundle, given a logical key maps to the path to the asset specified in the `pubspec.yaml` file:
- a string/text asset (`loadString()`)
- an image/binary asset (`load()`)

## Loading text assets

Each app has a [rootBundle](https://api.flutter.dev/flutter/services/rootBundle.html) object for easy access to the main asset bundle from `package:flutter/services.dart`.

It's recommended to obtain the `AssetBundle` for the current `BuildContext` using [DefaultAssetBundle](https://api.flutter.dev/flutter/widgets/DefaultAssetBundle-class.html), rather than the default asset bundle that was built with the app (e.g., Use `DefaultAssetBundle.of()` to indirectly load an asset, for example a JSON file, from the app's runtime `rootBundle`) => enables a parent widget to substitute a different `AssetBundle` at run time, which can be useful for localization or testing scenarios.

Outside of a `Widget` context, or when a handle to an `AssetBundle` is not available, you can use rootBundle to directly load such assets. For example:

```dart
import 'package:flutter/services.dart' show rootBundle;

Future<String> loadAsset() async {
  return await rootBundle.loadString('assets/config.json');
}
```

## Loading images

To load an image, use the [AssetImage](https://api.flutter.dev/flutter/painting/AssetImage-class.html) class in a widget's `build()` method.

```dart
return const Image(image: AssetImage('assets/background.png'));
```

## Resolution-aware image assets

`AssetImage` will map a logical requested asset onto one that most closely matches the current device pixel ratio. For this to work, assets should be arranged according to a particular directory structure. For example:

```dart
.../my_icon.png       (mdpi baseline)
.../1.5x/my_icon.png  (hdpi)
.../2.0x/my_icon.png  (xhdpi)
.../3.0x/my_icon.png  (xxhdpi)
.../4.0x/my_icon.png  (xxxhdpi)
```

`1.5` in `1.5x` are numeric identifiers that correspond to the nominal resolution of the images contained within. It specifies the device pixel ratio that the images are intended for. On devices with a device pixel ratio of `1.8`, the asset `.../2.0x/my_icon.png` is chosen.

[Device pixel ratio](https://api.flutter.dev/flutter/dart-ui/FlutterView/devicePixelRatio.html) depends on [MediaQueryData.size](https://api.flutter.dev/flutter/widgets/MediaQueryData/size.html), which requires having either `MaterialApp` or `CupertinoApp` as an ancestor of your `AssetImage`.

### Bundling of resolution-aware image assets

Only need to specify the main asset or its parent directory in the assets section of `pubspec.yaml`. Flutter will bundle the variants.

## Asset images in package dependencies

To load an image from a [package](https://docs.flutter.dev/packages-and-plugins/using-packages) dependency, the `package` argument must be provided to `AssetImage`:

```dart
return const AssetImage('icons/heart.png', package: 'my_icons');
```

### Bundling of package assets

Assets used by the package itself must be specified in its `pubspec.yaml`.

A package can also choose to have assets in its `lib/` folder that are not specified in its `pubspec.yaml` file. In this case,the application has to specify which ones to include in its `pubspec.yaml` (The `lib/` is implied, so it should not be included in the asset path). For example:

```dart
flutter:
  assets:
    - packages/fancy_backgrounds/backgrounds/background1.png
```

# Sharing assets with the underlying platform

Flutter assets are readily available to platform code using the `AssetManager` on Android and `NSBundle` on iOS

## Loading Flutter assets in Android

The assets are available through the [AssetManager](https://developer.android.com/reference/android/content/res/AssetManager) API. 

```dart
AssetManager assetManager = registrar.context().getAssets();
String key = registrar.lookupKeyForAsset("icons/heart.png");
AssetFileDescriptor fd = assetManager.openFd(key);
```

## Loading Flutter assets in iOS

The assets are available through the [mainBundle](https://developer.apple.com/documentation/foundation/nsbundle/1410786-mainbundle).

```dart
let key = controller.lookupKey(forAsset: "icons/heart.png")
let mainBundle = Bundle.main
let path = mainBundle.path(forResource: key, ofType: nil)
```

## Loading iOS images in Flutter

Use the [ios_platform_images](https://pub.dev/packages/ios_platform_images) plugin available on pub.dev.

# Platform assets

Below are two common cases where assets are used before the Flutter framework is loaded and running:

## Updating the app icon

### Android

Navigate to `.../android/app/src/main/res` and replace images named `ic_launcher.png` with your desired assets respecting the recommended icon size per screen density.

### iOS

Navigate to `.../ios/Runner` and replace the `Assets.xcassets/AppIcon.appiconset` directory that already contains placeholder images with the appropriately sized images.

## Updating the launch screen

If you you don't call `runApp()` in the `main()` function of your app, the launch screen persists forever.

### Android

Navigate to `.../android/app/src/main`. In `res/drawable/launch_background.xml`, use this [layer list drawable](https://developer.android.com/guide/topics/resources/drawable-resource#LayerList) XML to customize the look of your launch screen.

Ref: [Adding a splash screen to your Android app](https://docs.flutter.dev/platform-integration/android/splash-screen).

### iOS

Navigate to `.../ios/Runner`. In `ssets.xcassets/LaunchImage.imageset`, update the images named `LaunchImage.png`, `LaunchImage@2x.png`, `LaunchImage@3x.png`.

Ref: [Adding a splash screen to your iOS app](https://docs.flutter.dev/platform-integration/ios/splash-screen).
