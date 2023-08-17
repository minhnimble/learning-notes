# Intro

To share application state between screens, we need to deal with state in Flutter apps.

# Start thinking declaratively

It's okay to rebuild parts of your UI from scratch instead of modifying it.

Flutter is declarative, meaning that Flutter builds its user interface to reflect the current state of your app:

![Screenshot 2023-08-17 at 11 46 23](https://github.com/minhnimble/learning-notes/assets/70877098/ae4aebcc-c432-487d-8af8-64402fa85ce9)

Changing the state will trigger a redraw of the user interface. 

# Differentiate between ephemeral state and app state

The state of an app is everything that exists in memory when the app is running, including the app's assets, all the variables that the Flutter framework keeps about the UI, animation state, textures, fonts, and so on.

__State__ is “whatever data you need in order to rebuild your UI at any moment in time”. It can be separated into two conceptual types: ephemeral state and app state.

## Ephemeral state

This (sometimes called UI state or local state) is the state you can neatly contain in a single widget. For example:

- current page in a `PageView`
- current progress of a complex animation
- current selected tab in a `BottomNavigationBar`

=> No need to use state management techniques (ScopedModel, Redux, etc.) on this kind of state. All you need is a `StatefulWidget`:

```dart
class MyHomepage extends StatefulWidget {
  const MyHomepage({super.key});

  @override
  State<MyHomepage> createState() => _MyHomepageState();
}

class _MyHomepageState extends State<MyHomepage> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: _index,
      onTap: (newIndex) {
        setState(() {
          _index = newIndex;
        });
      },
      // ... items ...
    );
  }
}
```

## App state

This (sometimes called shared state) is the state that you want to share across many parts of your app or keep between user sessions. For example:

- User preferences
- Login info
- Notifications in a social networking app
- The shopping cart in an e-commerce app
- Read/unread state of articles in a news app

## No clear-cut rule

Basically, you can use `State` and `setState()` to manage all of the state in your app.

There is no clear-cut, universal rule to distinguish whether a particular variable is ephemeral or app state, and even have to refactor one into another:

![Screenshot 2023-08-17 at 11 57 03](https://github.com/minhnimble/learning-notes/assets/70877098/da86104d-2c29-4e57-a38c-66efde586611)

=> “The rule of thumb is: [Do whatever is less awkward](https://github.com/reduxjs/redux/issues/1287#issuecomment-175351978)”

# Simple app state management (using Provider package)

## Accessing the state

To add the `provider` package as a dependency, run flutter pub add: `$flutter pub add provider`

With `provider`, you don't need to worry about callbacks or `InheritedWidgets`. But you do need to understand 3 concepts:

- ChangeNotifier
- ChangeNotifierProvider
- Consumer

## ChangeNotifier

`ChangeNotifier` is a simple class which provides change notification to its listeners.

The only code that is specific to `ChangeNotifier` is the call to `notifyListeners()`. Call this method any time the model changes in a way that might change your app's UI.

## ChangeNotifierProvider

`ChangeNotifierProvider` is the widget that provides an instance of a `ChangeNotifier` to its descendants.

```dart
void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => CartModel(),
      child: const MyApp(),
    ),
  );
}
```

=> There is a builder that creates a new instance of `CartModel.ChangeNotifierProvider` and it is smart enough not to rebuild `CartModel` unless absolutely necessary. It also automatically calls `dispose()` on `CartModel` when the instance is no longer needed.

If you want to provide more than one class, you can use `MultiProvider`

```dart
void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => CartModel()),
        Provider(create: (context) => SomeOtherClass()),
      ],
      child: const MyApp(),
    ),
  );
}
```

## Consumer

Once provided to widgets in our app through the `ChangeNotifierProvider` declaration at the top, we can start using it through the `Consumer` widget.

```dart
return Consumer<CartModel>(
  builder: (context, cart, child) => Stack(
    children: [
      // Use SomeExpensiveWidget here, without rebuilding every time.
      if (child != null) child,
      Text('Total price: ${cart.totalPrice}'),
    ],
  ),
  // Build the expensive widget here.
  child: const SomeExpensiveWidget(),
);
```

=> It is best practice to put your `Consumer` widgets as deep in the tree as possible. You don't want to rebuild large portions of the UI just because some detail somewhere changed.

## Provider.of

Sometimes, you don't really need the data in the model to change the UI but you still need to access it (e.g., ClearCart button doesn't need to display the contents of the cart, it just needs to call the `clear()` method). For this use case, we can use `Provider.of`, with the `listen` parameter set to `false`:

```dart
Provider.of<CartModel>(context, listen: false).removeAll();
```

Full code example: https://github.com/flutter/samples/tree/main/provider_shopper

# State management options

- Provider
- Riverpod
- setState
- InheritedWidget & InheritedModel
- Redux
- Fish-Redux
- BLoC / Rx
- MobX
- Flutter Commands
- Binder
- GetX
- states_rebuilder
- Triple Pattern (Segmented State Pattern)
- solidart
- flutter_reactive_value

https://docs.flutter.dev/data-and-backend/state-mgmt/options
