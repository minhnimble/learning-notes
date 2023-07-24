# Intro

FVM helps to manage, switching between flutter versions on your development machine easily. Configure FVM and IDEs for better support for different development environments.

# Configuration

## Project

Create a relative symlink in your project from `.fvm/flutter_sdk` to the cache of the selected version. 

Add it to your `.gitignore`.

## IDE

### Android Studio

1. Go to `Languages & Frameworks > Flutter` or search for Flutter and change Flutter SDK path.
2. Copy the __absolute__ path of fvm symbolic link in your root project directory. Example: `/absolute-project-path/.fvm/flutter_sdk`
3. Apply the changes.
4. Restart Android Studio to see the new settings applied.

Note:
- Using `fvm install <VERSION>` will ensure that setup during install.
- Finish fvm install through another uncompleted setup by running `fvm flutter --version`.

To ignore the Flutter SDK root directory within Android Studio, add the following to `.idea/workspace.xml`:

```xml
<component name="VcsManagerConfiguration">
  <ignored-roots>
    <path value="$PROJECT_DIR$/.fvm/flutter_sdk" />
  </ignored-roots>
</component>
```

If that doesn't work, go to `Android Studio -> Preferences -> Editor -> File Types -> Ignored Files and Folders` and add `flutter_sdk`. Ref: https://fvm.app/docs/getting_started/configuration/
