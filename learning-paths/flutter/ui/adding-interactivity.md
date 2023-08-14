# Stateful and stateless widgets

A _stateless_ widget never changes. 

A _stateful_ widget is dynamic, i.e., a widget can change when a user interacts with it.

# Steps creating a stateful widget

## Step 1: Decide which object manages the widget's state

How state is managed: https://docs.flutter.dev/ui/interactivity#managing-state.

## Step 2: Subclass StatefulWidget

- The Widge class manages its own state by overriding `createState()` to create a `State` object.

- The framework calls `createState()` when it wants to build the widget.

## Step 3: Subclass State

The `State` class stores the mutable data that can change over the lifetime of the widget. 

Note: Members or classes that start with an underscore (`_`) are private.

```dart
class _FavoriteWidgetState extends State<FavoriteWidget> {
  bool _isFavorited = true;
  int _favoriteCount = 41;

  // ···
}
```

## Step 4: Plug the stateful widget into the widget tree

Add your custom stateful widget to the widget tree in the app's build() method.

Example codes:
- [lib/main.dart](https://github.com/flutter/website/tree/main/examples/layout/lakes/interactive/lib/main.dart)
- [pubspec.yaml](https://github.com/flutter/website/tree/main/examples/layout/lakes/interactive/pubspec.yaml)
- [lakes.jpg](https://github.com/flutter/website/tree/main/examples/layout/lakes/interactive/images/lake.jpg)

# Managing state

The parent widget manages the state and tells its child widget when to update.

```dart
import 'package:flutter/material.dart';

// ParentWidget manages the state for TapboxB.

//------------------------ ParentWidget --------------------------------

class ParentWidget extends StatefulWidget {
  const ParentWidget({super.key});

  @override
  State<ParentWidget> createState() => _ParentWidgetState();
}

class _ParentWidgetState extends State<ParentWidget> {
  bool _active = false;

  void _handleTapboxChanged(bool newValue) {
    setState(() {
      _active = newValue;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      child: TapboxB(
        active: _active,
        onChanged: _handleTapboxChanged,
      ),
    );
  }
}

//------------------------- TapboxB ----------------------------------

class TapboxB extends StatelessWidget {
  const TapboxB({
    super.key,
    this.active = false,
    required this.onChanged,
  });

  final bool active;
  final ValueChanged<bool> onChanged;

  void _handleTap() {
    onChanged(!active);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      child: Container(
        width: 200,
        height: 200,
        decoration: BoxDecoration(
          color: active ? Colors.lightGreen[700] : Colors.grey[600],
        ),
        child: Center(
          child: Text(
            active ? 'Active' : 'Inactive',
            style: const TextStyle(fontSize: 32, color: Colors.white),
          ),
        ),
      ),
    );
  }
}
```

# A mix-and-match approach

For some widgets, a mix-and-match approach makes the most sense => The stateful widget manages some of the state, and the parent widget manages other aspects of the state.

```dart
import 'package:flutter/material.dart';

//---------------------------- ParentWidget ----------------------------

class ParentWidget extends StatefulWidget {
  const ParentWidget({super.key});

  @override
  State<ParentWidget> createState() => _ParentWidgetState();
}

class _ParentWidgetState extends State<ParentWidget> {
  bool _active = false;

  void _handleTapboxChanged(bool newValue) {
    setState(() {
      _active = newValue;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      child: TapboxC(
        active: _active,
        onChanged: _handleTapboxChanged,
      ),
    );
  }
}

//----------------------------- TapboxC ------------------------------

class TapboxC extends StatefulWidget {
  const TapboxC({
    super.key,
    this.active = false,
    required this.onChanged,
  });

  final bool active;
  final ValueChanged<bool> onChanged;

  @override
  State<TapboxC> createState() => _TapboxCState();
}

class _TapboxCState extends State<TapboxC> {
  bool _highlight = false;

  void _handleTapDown(TapDownDetails details) {
    setState(() {
      _highlight = true;
    });
  }

  void _handleTapUp(TapUpDetails details) {
    setState(() {
      _highlight = false;
    });
  }

  void _handleTapCancel() {
    setState(() {
      _highlight = false;
    });
  }

  void _handleTap() {
    widget.onChanged(!widget.active);
  }

  @override
  Widget build(BuildContext context) {
    // This example adds a green border on tap down.
    // On tap up, the square changes to the opposite state.
    return GestureDetector(
      onTapDown: _handleTapDown, // Handle the tap events in the order that
      onTapUp: _handleTapUp, // they occur: down, up, tap, cancel
      onTap: _handleTap,
      onTapCancel: _handleTapCancel,
      child: Container(
        width: 200,
        height: 200,
        decoration: BoxDecoration(
          color: widget.active ? Colors.lightGreen[700] : Colors.grey[600],
          border: _highlight
              ? Border.all(
                  color: Colors.teal[700]!,
                  width: 10,
                )
              : null,
        ),
        child: Center(
          child: Text(widget.active ? 'Active' : 'Inactive',
              style: const TextStyle(fontSize: 32, color: Colors.white)),
        ),
      ),
    );
  }
}
```

# Other interactive widgets

use [GestureDetector](https://api.flutter.dev/flutter/widgets/GestureDetector-class.html) to build interactivity into any custom widget.

 Flutter also provides a set of iOS-style widgets called [Cupertino](https://api.flutter.dev/flutter/cupertino/cupertino-library.html).

Standard widgets

- [Form](https://api.flutter.dev/flutter/widgets/Form-class.html)
- [FormField](https://api.flutter.dev/flutter/widgets/FormField-class.html)

Material Components

- [Checkbox](https://api.flutter.dev/flutter/material/Checkbox-class.html)
- [DropdownButton](https://api.flutter.dev/flutter/material/DropdownButton-class.html)
- [TextButton](https://api.flutter.dev/flutter/material/TextButton-class.html)
- [FloatingActionButton](https://api.flutter.dev/flutter/material/FloatingActionButton-class.html)
- [IconButton](https://api.flutter.dev/flutter/material/IconButton-class.html)
- [Radio](https://api.flutter.dev/flutter/material/Radio-class.html)
- [ElevatedButton](https://api.flutter.dev/flutter/material/ElevatedButton-class.html)
- [Slider](https://api.flutter.dev/flutter/material/Slider-class.html)
- [Switch](https://api.flutter.dev/flutter/material/Switch-class.html)
- [TextField](https://api.flutter.dev/flutter/material/TextField-class.html)
