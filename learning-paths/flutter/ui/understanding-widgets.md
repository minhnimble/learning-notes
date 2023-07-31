# Intro

Flutter widgets are built using a modern framework that takes inspiration from [React](https://react.dev/).

# Basic Widgets

- Use the [Positioned](https://api.flutter.dev/flutter/widgets/Positioned-class.html) widget on children of a Stack to position them relative to the top, right, bottom, or left edge of the stack.

- Have a `uses-material-design: true` entry in the flutter section of your `pubspec.yaml` file to use the predefined set of [Material icons](https://design.google.com/icons/).

```yaml
name: my_app
flutter:
  uses-material-design: true
```

# Using Material Components

- [Navigator](https://api.flutter.dev/flutter/widgets/Navigator-class.html), which manages a stack of widgets identified by strings, also known as “routes” and allows smooth transition between screens of the application. 

- Using the [MaterialApp](https://api.flutter.dev/flutter/material/MaterialApp-class.html) widget is optional but a good practice.

- [AppBar](https://api.flutter.dev/flutter/material/AppBar-class.html) widget lets you pass in widgets for the [leading](https://api.flutter.dev/flutter/material/AppBar-class.html#leading) widget, and the [actions](https://api.flutter.dev/flutter/material/AppBar-class.html#actions) of the [title](https://api.flutter.dev/flutter/material/AppBar-class.html#title) widget.

- Material is one of the 2 bundled designs included with Flutter. To create an iOS-centric design, check out the [Cupertino components](https://docs.flutter.dev/ui/widgets/cupertino) package, which has its own versions of [CupertinoApp](https://api.flutter.dev/flutter/cupertino/CupertinoApp-class.html), and [CupertinoNavigationBar](https://api.flutter.dev/flutter/cupertino/CupertinoNavigationBar-class.html).

# Handling gestures

The [GestureDetector](https://api.flutter.dev/flutter/widgets/GestureDetector-class.html) widget doesn’t have a visual representation but instead detects gestures made by the user. When the user taps the Container, the `GestureDetector` calls its `onTap()` callback, in this case printing a message to the console. You can use `GestureDetector` to detect a variety of input gestures, including taps, drags, and scales.

```dart
import 'package:flutter/material.dart';

class MyButton extends StatelessWidget {
  const MyButton({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        print('MyButton was tapped!');
      },
      child: Container(
        height: 50,
        padding: const EdgeInsets.all(8),
        margin: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(5),
          color: Colors.lightGreen[500],
        ),
        child: const Center(
          child: Text('Engage'),
        ),
      ),
    );
  }
}
```

# Changing widgets in response to input

- Stateless widgets receive arguments from their parent widget, which they store in [final](https://dart.dev/language/variables#final-and-const) member variables. When a widget is asked to [build()](https://api.flutter.dev/flutter/widgets/StatelessWidget/build.html), it uses these stored values to derive new arguments for the widgets it creates.

- Stateful widgets know how to generate `State` objects, which are then used to hold state.

```dart
import 'package:flutter/material.dart';

class CounterDisplay extends StatelessWidget {
  const CounterDisplay({required this.count, super.key});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Text('Count: $count');
  }
}

class CounterIncrementor extends StatelessWidget {
  const CounterIncrementor({required this.onPressed, super.key});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      child: const Text('Increment'),
    );
  }
}

class Counter extends StatefulWidget {
  const Counter({super.key});

  @override
  State<Counter> createState() => _CounterState();
}

class _CounterState extends State<Counter> {
  int _counter = 0;

  void _increment() {
    setState(() {
      ++_counter;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        CounterIncrementor(onPressed: _increment),
        const SizedBox(width: 16),
        CounterDisplay(count: _counter),
      ],
    );
  }
}

// Main execution
void main() {
  runApp(
    const MaterialApp(
      home: Scaffold(
        body: Center(
          child: Counter(),
        ),
      ),
    ),
  );
}
```

- `StatefulWidget` and `State` are separate objects:
  - `Widgets` are temporary objects, used to construct a presentation of the application in its current state. 
  - `State` objects, on the other hand, are persistent between calls to build(), allowing them to remember information.

- In Flutter, change notifications flow “up” the widget hierarchy by way of callbacks, while current state flows “down” to the stateless widgets that do presentation.

# Responding to widget lifecycle events

- After calling [createState()](https://api.flutter.dev/flutter/widgets/StatefulWidget-class.html#createState) on the `StatefulWidget`, the framework inserts the new state object into the tree and then calls [initState()](https://api.flutter.dev/flutter/widgets/State-class.html#initState) on the state object.

- A subclass of [State](https://api.flutter.dev/flutter/widgets/State-class.html) can override `initState` to do work that needs to happen just once, e.g., configure animations or to subscribe to platform services.
  - Implementations of `initState` are required to start by calling `super.initState`.

- When a state object is no longer needed, the framework calls [dispose()](https://api.flutter.dev/flutter/widgets/State-class.html#dispose) on the state object:
  - Override the `dispose` function to do cleanup work, e.g., cancel timers or to unsubscribe from platform services.
  - Implementations of dispose typically end by calling `super.dispose`. 

# Keys

- Use keys to control which widgets the framework matches up with other widgets when a widget rebuilds. The framework requires that the two widgets have the same [key](https://api.flutter.dev/flutter/foundation/Key-class.html) as well as the same [runtimeType](https://api.flutter.dev/flutter/widgets/Widget-class.html#runtimeType).

- Keys are most useful in widgets that build many instances of the same type of widget e.g., list of widgets instances (`ShoppingListItem`).

- Without keys, the first entry in the current build would always sync with the first entry in the previous build, even if, semantically, the first entry in the list just scrolled off screen and is no longer visible in the viewport.

- By assigning each entry in the list a “semantic” key, the infinite list can be more efficient because the framework syncs entries with matching semantic keys and therefore similar (or identical) visual appearances -> Syncing the entries semantically means that state retained in stateful child widgets remains attached to the same semantic entry rather than the entry in the same numerical position in the viewport.

# Global keys

- Use global keys to uniquely identify child widgets.

- Global keys must be globally unique across the entire widget hierarchy, unlike local keys which need only be unique among siblings.

- A global key can be used to retrieve the state associated with a widget.