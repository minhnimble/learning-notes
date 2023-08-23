# Intro

[Riverpod](https://pub.dev/packages/riverpod) is a reactive caching and data-binding framework that was born as a complete rewrite the [Provider](https://pub.dev/packages/provider) package. It can be used to:
- catch programming errors at __compile-time__ rather than at runtime.
- easily __fetch__, __cache__, and __update__ data from a remote source.
- perform __reactive caching__ and easily update your UI.
- depend on __asynchronous__ or __computed__ state.
- __create__, __use__, and __combine__ providers with minimal boilerplate code.
- __dispose__ the state of a provider when it is no longer used.
- write __testable code__ and keep your logic outside the widget tree.

# Why Riverpod

The main __drawback__ of the Provider package: Provider is an improvement over [InheritedWidget](https://api.flutter.dev/flutter/widgets/InheritedWidget-class.html), and thus it depends on the widget tree → lead to the common `ProviderNotFoundException`.

Riverpod is __compile-safe__ since all providers are declared __globally__ and can be accessed anywhere → can create providers to hold your application state and business logic outside the widget tree.

# Installation

Add the latest version of `flutter_riverpod` as a dependency to our `pubspec.yaml` file:

```yaml
dependencies:
  flutter:
    sdk: flutter  
  flutter_riverpod: ^2.3.6
```

To more easily add Riverpod providers in your code, install the Flutter Riverpod Snippets extension for [VSCode](https://marketplace.visualstudio.com/items?itemName=robert-brunhage.flutter-riverpod-snippets) or [Android Studio / IntelliJ](https://plugins.jetbrains.com/plugin/14641-flutter-riverpod-snippets).

## ProviderScope

ProviderScope is a widget that stores the state of all the providers we create.

Usage: Wrap our root widget with a `ProviderScope`:

```dart
void main() {
  // wrap the entire app with a ProviderScope so that widgets
  // will be able to read providers
  runApp(ProviderScope(
    child: MyApp(),
  ));
}
```

For more details about `ProviderContainer` and `UncontrolledProviderScope`, read: https://codewithandrea.com/articles/riverpod-initialize-listener-app-startup/

## Riverpod Provider

It is a provider object that encapsulates a piece of state and allows listening to that state:
- Replace design patterns such as __singletons__, __service locators__, __dependency injection__, and __InheritedWidgets__.
- Store some state and easily access it in multiple locations.
- Optimize performance by filtering widget rebuilds or caching expensive state computations.
- Make the code more testable, since each provider can be overridden to behave differently during a test.

### Create a Provider

```dart
// provider that returns a string value
final helloWorldProvider = Provider<String>((_) => 'Hello world');
```

### Usage

1. Use a `ConsumerWidget`

```dart
// 1. widget class now extends [ConsumerWidget]
class HelloWorldWidget extends ConsumerWidget {
  @override
  // 2. build method has an extra [WidgetRef] argument
  Widget build(BuildContext context, WidgetRef ref) {
    // 3. use ref.watch() to get the value of the provider
    final helloWorld = ref.watch(helloWorldProvider);
    return Text(helloWorld);
  }
}
```

→ If you create widgets that are small and reusable favours composition, leading to code that is concise, more performant, and easier to reason about, then you'll naturally use `ConsumerWidget` most of the time.

2. Use a `Consumer`

```dart
lass HelloWorldWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // 1. Add a Consumer
    return Consumer(
      // 2. specify the builder and obtain a WidgetRef
      builder: (_, WidgetRef ref, __) {
        // 3. use ref.watch() to get the value of the provider
        final helloWorld = ref.watch(helloWorldProvider);
        return Text(helloWorld);
      },
    );
  }
}
```

→ If you have a big widget class with a complex layout, you can use `Consumer` to rebuild only the widgets that depend on the provider. 

3. Using `ConsumerStatefulWidget` & `ConsumerState`

```dart
// 1. extend [ConsumerStatefulWidget]
class HelloWorldWidget extends ConsumerStatefulWidget {
  @override
  ConsumerState<HelloWorldWidget> createState() => _HelloWorldWidgetState();
}

// 2. extend [ConsumerState]
class _HelloWorldWidgetState extends ConsumerState<HelloWorldWidget> {
  @override
  void initState() {
    super.initState();
    // 3. if needed, we can read the provider inside initState
    final helloWorld = ref.read(helloWorldProvider);
    print(helloWorld); // "Hello world"
  }

  @override
  Widget build(BuildContext context) {
    // 4. use ref.watch() to get the value of the provider
    final helloWorld = ref.watch(helloWorldProvider);
    return Text(helloWorld);
  }
}
```

## WidgetRef

It is an object that allows widgets to interact with providers and access any provider. There are some similarities between `BuildContext` and [WidgetRef](https://pub.dev/documentation/flutter_riverpod/latest/flutter_riverpod/WidgetRef-class.html):
- `BuildContext` lets us access ancestor widgets in the widget tree (such as Theme.of(context) and MediaQuery.of(context)).
- `WidgetRef` lets us access any provider inside our app.

## Provider types

There are a total of 8 types:
- __Provider__ → is for accessing dependencies and objects that don't change, e.g., date formatter.

- __StateProvider__ (legacy, use `Notifier` related objects instead) → is for storing simple state objects that can change like enums, strings, booleans, and numbers, e.g., a counter value.
- __StateNotifierProvider__ (legacy, use `FutureProvider` instead) → listen to and expose a `StateNotifier`. 
⇒ `StateNotifierProvider` and `StateNotifier` are for managing state that may change in reaction to an event or user interaction, e.g., Clock time change event every second.

- __FutureProvider__ → get the result from an API call that returns a `Future` and often used with the `autoDispose` modifier. Here are some usage:
   1. perform and cache asynchronous operations (such as network requests)
   2. handle the error and loading states of asynchronous operations
   3. combine multiple asynchronous values into another value
   4. re-fetch and refresh data (useful for pull-to-refresh operations)

- __StreamProvider__ → watch a `Stream` of results from a realtime API and __reactively__ rebuild the UI.

- ChangeNotifierProvider (legacy, use `StateNotifier` instead) → is for storing some state and notify listeners when it changes. However, it makes easy to break two important rules: __immutable state__ and __unidirectional data flow__.

- __NotifierProvider__ (new in Riverpod 2.0)
- __AsyncNotifierProvider__ (new in Riverpod 2.0)
→ Riverpod 2.0 introduced new [Notifier](https://pub.dev/documentation/riverpod/latest/riverpod/Notifier-class.html) and [AsyncNotifier](https://pub.dev/documentation/riverpod/latest/riverpod/AsyncNotifier-class.html) classes, along their corresponding providers. Ref: [How to use Notifier and AsyncNotifier with the new Flutter Riverpod Generator](https://codewithandrea.com/articles/flutter-riverpod-async-notifier/)

## ref.watch vs ref.read

- call `ref.watch(provider)` to observe a provider's state in the `build` method and __rebuild__ a widget when it changes.
- call `ref.read(provider)` to read a provider's state just once (this can be useful in `initState` or other `lifecycle methods`).

The `.notifier` syntax is available with `StateProvider` and `StateNotifierProvider` only and works as follows:
- call `ref.read(provider.notifier)` on a `StateProvider<T>` to return the underlying `StateController<T>` that we can use to modify the state.
- call `ref.read(provider.notifier)` on a `StateNotifierProvider<T>` to return the underlying `StateNotifier<T>` so we can call methods on it.

## ref.listen

Sometimes we want to show an alert dialog or a `SnackBar` when a provider state changes.

```dart
final counterStateProvider = StateProvider<int>((_) => 0);

class CounterWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // if we use a StateProvider<T>, the type of the previous and current 
    // values is StateController<T>
    ref.listen<StateController<int>>(counterStateProvider.state, (previous, current) {
      // note: this callback executes when the provider value changes,
      // not when the build method is called
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Value is ${current.state}')),
      );
    });
    // watch the provider and rebuild when the value changes
    final counter = ref.watch(counterStateProvider);
    return ElevatedButton(
      // use the value
      child: Text('Value: $counter'),
      // change the state inside a button callback
      onPressed: () => ref.read(counterStateProvider.notifier).state++,
    );
  }
}
```

# Additional Riverpod Features

## autoDispose modifier

When working with `FutureProvider` or `StreamProvider`, we'll want to dispose of any listeners when our provider is no longer in use to ensure that the stream connection is closed as soon as we leave the page where we're watching the provider.

```dart
final authStateChangesProvider = StreamProvider.autoDispose<User?>((ref) {
  // get FirebaseAuth from another provider
  final firebaseAuth = ref.watch(firebaseAuthProvider);
  // call method that returns a Stream<User?>
  return firebaseAuth.authStateChanges();
});
```

If desired, we can call `ref.keepAlive()` to preserve the state so that the request won't fire again if the user leaves and re-enters the same screen.

Example usage: a [KeepAliveLink](https://pub.dev/documentation/riverpod/latest/riverpod/KeepAliveLink-class.html) to implement a timeout-based caching strategy to dispose the provider's state after a given duration.

## family modifier

`family` is a modifier that we can use to pass an argument to a provider by adding a second type annotation and an additional parameter that we can use inside the provider body:

```dart
final movieProvider = FutureProvider.autoDispose
    // additional movieId argument of type int
    .family<TMDBMovieBasic, int>((ref, movieId) async {
  // get the repository
  final moviesRepo = ref.watch(fetchMoviesRepositoryProvider);
  // call method that returns a Future<TMDBMovieBasic>, passing the movieId as an argument
  return moviesRepo.movie(movieId: movieId, cancelToken: cancelToken);
});

class MovieDetailsScreen extends ConsumerWidget {
  const MovieDetailsScreen({super.key, required this.movieId});
  // pass this as a property
  final int movieId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // fetch the movie data for the given movieId
    final movieAsync = ref.watch(movieProvider(movieId));
    // map to the UI using pattern matching
    return movieAsync.when(
      data: (movie) => MovieWidget(movie: movie),
      loading: (_) => Center(child: CircularProgressIndicator()),
      error: (e, __) => Center(child: Text(e.toString())),
    );
  }
}
```

## Passing multiple parameters to a family

Riverpod does not support this, you can pass any custom object that implements `hashCode` and the equality operator (objects that use [equatable](https://pub.dev/packages/equatable)).

## Dependency Overrides with Riverpod

Sometimes we want to create a Provider to store a value or object that is not __immediately__ available.

```dart
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError();
});

// asynchronous initialization can be performed in the main method
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final sharedPreferences = await SharedPreferences.getInstance();
  runApp(ProviderScope(
    overrides: [
      // override the previous value with the new object
      sharedPreferencesProvider.overrideWithValue(sharedPreferences),
    ],
    child: MyApp(),
  ));
}
```

## Combining Providers with Riverpod

Providers can depend on other providers, e.g., `SettingsRepository` class that takes an explicit `SharedPreferences`.

```dart
class SettingsRepository {
  const SettingsRepository(this.sharedPreferences);
  final SharedPreferences sharedPreferences;

  // synchronous read
  bool onboardingComplete() {
    return sharedPreferences.getBool('onboardingComplete') ?? false;
  }

  // asynchronous write
  Future<void> setOnboardingComplete(bool complete) {
    return sharedPreferences.setBool('onboardingComplete', complete);
  }
}

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  // watch another provider to obtain a dependency. Using ref.watch() ensures that the provider is updated when the provider we depend on changes. As a result, any dependent widgets and providers will rebuild too.
  final sharedPreferences = ref.watch(sharedPreferencesProvider);
  // pass it as an argument to the object we need to return
  return SettingsRepository(sharedPreferences);
});
```

As an alternative, we can pass `Ref` as an argument when creating the `SettingsRepository`:

```dart
class SettingsRepository {
  const SettingsRepository(this.ref);
  final Ref ref;

  // synchronous read
  bool onboardingComplete() {
    final sharedPreferences = ref.read(sharedPreferencesProvider);
    return sharedPreferences.getBool('onboardingComplete') ?? false;
  }

  // asynchronous write
  Future<void> setOnboardingComplete(bool complete) {
    final sharedPreferences = ref.read(sharedPreferencesProvider);
    return sharedPreferences.setBool('onboardingComplete', complete);
  }
}

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepository(ref);
});
```

→ The `sharedPreferencesProvider` becomes an implicit dependency, and we can access it with a call to `ref.read()`.

## Scoping Providers

For a `ListView`, we can override the provider value inside a nested `ProviderScope`:

```dart
// 1. Declare a Provider
final currentProductIndex = Provider<int>((_) => throw UnimplementedError());

class ProductList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView.builder(itemBuilder: (context, index) {
      // 2. Add a parent ProviderScope
      return ProviderScope(
        overrides: [
          // 3. Add a dependency override on the index
          currentProductIndex.overrideWithValue(index),
        ],
        // 4. return a **const** ProductItem with no constructor arguments
        child: const ProductItem(),
      );
    });
  }
}

class ProductItem extends ConsumerWidget {
  const ProductItem({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 5. Access the index via WidgetRef
    final index = ref.watch(currentProductIndex);
    // do something with the index
  }
}
```
This is better for performance because we can create `ProductItem` as a const widget in the `ListView.builder`. So even if the `ListView` rebuilds, our `ProductItem` will not rebuild unless its index has changed.

## Filter widgets rebuilds with select()

Sometimes you have a model class with multiple properties, and you want to rebuild a widget only when a specific property changes:

```dart
class Connection {
  Connection({this.bytesSent = 0, this.bytesReceived = 0});
  final int bytesSent;
  final int bytesReceived;
}

// Using [StateProvider] for simplicity.
// This would be a [FutureProvider] or [StreamProvider] in real-world usage.
final connectionProvider = StateProvider<Connection>((ref) {
  return Connection();
});

class BytesReceivedText extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // rebuild when bytesSent OR bytesReceived changes
    final counter = ref.watch(connectionProvider).state;
    return Text('${counter.bytesReceived}');
  }
}
```

Calling `ref.watch(connectionProvider)`, our widget will (incorrectly) rebuild when the bytesSent value changes → Use `select()` instead:

```dart
class BytesReceivedText extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // only rebuild when bytesReceived changes
    final bytesReceived = ref.watch(connectionProvider.select(
      (connection) => connection.state.bytesReceived
    ));
    return Text('$bytesReceived');
  }
}
```

## Testing with Riverpod

Separate widget tests will never share any state, so there is no need for `setUp` and `tearDown` methods.

Multiple tests don't share any state because each test has a different `ProviderScope`:

```dart
void main() {
  testWidgets('incrementing the state updates the UI', (tester) async {
    await tester.pumpWidget(ProviderScope(child: MyApp()));

    // The default value is `0`, as declared in our provider
    expect(find.text('0'), findsOneWidget);
    expect(find.text('1'), findsNothing);

    // Increment the state and re-render
    await tester.tap(find.byType(ElevatedButton));
    await tester.pump();

    // The state have properly incremented
    expect(find.text('1'), findsOneWidget);
    expect(find.text('0'), findsNothing);
  });

  testWidgets('the counter state is not shared between tests', (tester) async {
    await tester.pumpWidget(ProviderScope(child: MyApp()));

    // The state is `0` once again, with no tearDown/setUp needed
    expect(find.text('0'), findsOneWidget);
    expect(find.text('1'), findsNothing);
  });
}
```

To mock and override dependencies in tests, use dependency overrides to change the behaviour of a provider by replacing it with a different implementation, for example:

```dart
// 1. Create a MockMoviesRepository
class MockMoviesRepository implements MoviesRepository {
  @override
  Future<List<Movie>> favouriteMovies() {
    return Future.value([
      Movie(id: 1, title: 'Rick & Morty', posterUrl: 'https://nnbd.me/1.png'),
      Movie(id: 2, title: 'Seinfeld', posterUrl: 'https://nnbd.me/2.png'),
    ]);
  }
}

// 2. And in our widget tests, we can override the repository provider
void main() {
  testWidgets('Override moviesRepositoryProvider', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          moviesRepositoryProvider
              .overrideWithValue(MockMoviesRepository())
        ],
        child: MoviesApp(),
      ),
    );
  });
}
```

References: 
- [Riverpod testing guide](https://riverpod.dev/docs/cookbooks/testing/)
- [How to Unit Test AsyncNotifier Subclasses with Riverpod 2.0 in Flutter](https://codewithandrea.com/articles/unit-test-async-notifier-riverpod/)

## Logging with ProviderObserver

A [ProviderObserver](https://riverpod.dev/docs/concepts/provider_observer/) class can be sub-classed to implement a `Logger` that can be used for the entire app:

```dart
class Logger extends ProviderObserver {
  @override
  void didUpdateProvider(
    ProviderBase provider,
    Object? previousValue,
    Object? newValue,
    ProviderContainer container,
  ) {
    print('[${provider.name ?? provider.runtimeType}] value: $newValue');
  }
}

void main() {
  runApp(
    ProviderScope(observers: [Logger()], child: MyApp()),
  );
}
```

Add a name to our providers to improve logging:

```dart
final counterStateProvider = StateProvider<int>((ref) {
  return 0;
}, name: 'counter');
```

`ProviderObserver` is similar to the [BlocObserver](https://bloclibrary.dev/#/coreconcepts?id=blocobserver-1) widget from the `flutter_bloc` package.

# App architecture with Riverpod

![Screenshot 2023-08-21 at 15 30 58](https://github.com/minhnimble/learning-notes/assets/70877098/6e316ca8-90db-4648-bafc-b89b102611cd)

Ref: [Flutter App Architecture with Riverpod: An Introduction](https://codewithandrea.com/articles/flutter-app-architecture-riverpod-introduction/)

# Conclusion:

- Official Riverpod example apps: https://github.com/rrousselGit/riverpod/tree/master/examples
- Flutter App Architecture with Riverpod: An Introduction: https://codewithandrea.com/articles/flutter-app-architecture-riverpod-introduction/
