# Definition

Sometimes referred to as the `Virtual Constructor` pattern, provides a way to conceal an object's creation logic from client code, but the object returned is guaranteed to adhere to a known interface.

# Example code

```dart
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

abstract class PlatformButton {
  factory PlatformButton(TargetPlatform platform) {
    switch (platform) {
      case TargetPlatform.android: return AndroidButton();
      case TargetPlatform.iOS: return IosButton();
      default: return null;
    }
  }

  Widget build({
    @required BuildContext context,
    @required Widget child,
    @required VoidCallback onPressed
  });
}

class AndroidButton implements PlatformButton {
  @override
  Widget build({
    @required BuildContext context,
    @required Widget child,
    @required VoidCallback onPressed
  }) {
    return FlatButton(
      child: child,
      onPressed: onPressed,
    );
  }
}

class IosButton implements PlatformButton {
  @override
  Widget build({
    @required BuildContext context,
    @required Widget child,
    @required VoidCallback onPressed
  }) {
    return CupertinoButton(
      child: child,
      onPressed: onPressed,
    );
  }
}

// Then, a PlatformButton factory can be created and built
PlatformButton(Theme.of(context).platform).build(
  context: context,
  child: Text('My Button'),
  onPressed: () => print('Button pressed!'),
)
```

# The Abstract Factory Method pattern

## Definition

It is essentially a superset of the `Factory Method` pattern. With this pattern, client code no longer needs to concern itself with specific object factories. Instead, a central factory class (a factory of factories) handles those details invisibly. The user need only provide the type of object required, and the abstract factory determines which object factory to instantiate, then it returns the appropriate product.

## Example code

```dart
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

abstract class PlatformSwitch {
  factory PlatformSwitch(TargetPlatform platform) {
    switch (platform) {
      case TargetPlatform.android: return AndroidSwitch();
      case TargetPlatform.iOS: return IosSwitch();
      default: return null;
    }
  }

  Widget build({
    @required BuildContext context,
    @required value,
    @required ValueChanged<bool> onChanged
  });
}

class AndroidSwitch implements PlatformSwitch {
  @override
  Widget build({
    @required BuildContext context,
    @required value,
    @required ValueChanged<bool> onChanged
  }) {

    PlatformButton(Theme.of(context).platform);
    return Switch(
      value: value,
      onChanged: onChanged,
    );
  }
}

class IosSwitch implements PlatformSwitch {
  @override
  Widget build({
    @required BuildContext context,
    @required value,
    @required ValueChanged<bool> onChanged
  }) {
    return CupertinoSwitch(
      value: value,
      onChanged: onChanged,
    );
  }
}

class WidgetFactory {
  static Widget buildButton({
    @required BuildContext context,
    @required Widget child,
    @required VoidCallback onPressed
  }) {
    return PlatformButton(Theme.of(context).platform).build(
      context: context,
      child: child,
      onPressed: onPressed,
    );
  }

  static Widget buildSwitch({
    @required BuildContext context,
    @required value,
    @required ValueChanged<bool> onChanged
  }) {
    return PlatformSwitch(Theme.of(context).platform).build(
      context: context,
      value: value,
      onChanged: onChanged,
    );
  }
}

// Then, use the WidgetFactory to create the Switch by calling one of the build methods
WidgetFactory.buildSwitch(
  context: context,
  value: myValue,
  onChanged: (bool value) => print(value),
)
```
