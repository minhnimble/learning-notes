# Intro

- [Navigator](https://api.flutter.dev/flutter/widgets/Navigator-class.html): Use for small applications without complex deep linking.
- [Router](https://api.flutter.dev/flutter/widgets/Router-class.html): Additionally use for apps with specific deep linking and navigation requirements on Android and iOS, and to stay in sync with the address bar when the app is running on the web. Ref: [Deep linking](https://docs.flutter.dev/ui/navigation/deep-linking).

# Using the Navigator

The `Navigator` widget displays screens as a stack using the correct transition animations for the target platform. To navigate to a new screen, access the `Navigator` through the route's `BuildContext` and call imperative methods such as `push()` or `pop()`:

```dart
onPressed: () {
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (context) => const SongScreen(song: song),
    ),
  );
},
child: Text(song.name),
```

As `Navigator` keeps a stack of `Route` objects (representing the history stack), the `push()` method takes a `Route` object. The `MaterialPageRoute` object is a subclass of `Route` that specifies the transition animations for Material Design.

# Using named routes (Not recommended)

Applications with simple navigation and deep linking requirements can use the `Navigator` for navigation and the `MaterialApp.routes` parameter (named routes) for deep links:

```dart
@override
  Widget build(BuildContext context) {
  return MaterialApp(
    routes: {
      '/': (context) => HomeScreen(),
      '/details': (context) => DetailScreen(),
    },
  );
}
```

## Limitations

- The behavior is always the same and can't be customized, i.e., when a new deep link is received by the platform, Flutter pushes a new `Route` onto the `Navigator` regardless where the user currently is.

- Doesn't support the browser forward button.

# Using the Router

Use a routing package - [go_router](https://pub.dev/packages/go_router) that can parse the route path and configure the `Navigator` whenever the app receives a new deep link.

## Advanced 

If prefer not to use a routing package and would like full control over navigation and routing in your app, override `RouteInformationParser` and `RouterDelegate`. When the state in the app changes, can precisely control the stack of screens by providing a list of `Page` objects using the `Navigator.pages` parameter.

# Using Router and Navigator together

When navigate using the `Router` or a declarative routing package, each route on the Navigator is _page-backed_, meaning it was created from a [Page](https://api.flutter.dev/flutter/widgets/Page-class.html) using the [pages](https://api.flutter.dev/flutter/widgets/Navigator/pages.html) argument on the `Navigator` constructor.

When a page-backed `Route` is removed from the `Navigator`, all of the _pageless_ routes after it are also removed.
