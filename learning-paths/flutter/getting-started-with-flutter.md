# Intro

Flutter most closely resembles React Native - allow for a reactive and declarative style of programming. 

Unlike React Native, Flutter doesn’t need to use a JavaScript bridge, which improves app startup times and overall performance. 

Dart achieves this by using Ahead-Of-Time (AOT) compilation.

Dart can also use Just-In-Time (JIT) compilation. JIT compilation with Flutter improves the development workflow by allowing a hot reload capability to refresh the UI during development.

## Editing the Code

A basic white screen:

```dart
import 'package:flutter/material.dart';

void main() => runApp(const GHFlutterApp());

class GHFlutterApp extends StatelessWidget {
  const GHFlutterApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GHFlutter',
      home: Scaffold(
        appBar: AppBar(
          title: const Text('GHFlutter'),
        ),
        body: const Center(
          child: Text('GHFlutter'),
        ),
      ),
    );
  }
}
```

# Widgets

## Understanding Widgets

Almost every element of your Flutter app is a widget. Think of widgets like blueprints that tell how the UI should look. 

Widgets are designed to be immutable, or unchangeable, since using immutable widgets helps keep the app UI lightweight.

Two fundamental types of widgets:

- __Stateless__: Widgets that depend only upon their own configuration info, such as a static image in an image view.
- __Stateful__: Widgets that need to maintain dynamic information. They do so by interacting with a State object.

## Creating Widgets 

To make your own widgets, go to the bottom of `main.dart` and start typing `stful`, an abbreviation for “stateful”.

```dart
class GHFlutter extends StatefulWidget {
  const GHFlutter({ Key? key }) : super(key: key);

  @override
  _GHFlutterState createState() => _GHFlutterState();
}

class _GHFlutterState extends State<GHFlutter> {
  @override
  Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: const Text(strings.appTitle),
    ),
    body: const Text(strings.appTitle),
  );
}
```

A __Scaffold__ is a container for Material Design widgets. It acts as the root of a widget hierarchy. 

The keyword `const` indicates a compile-time constant and using it allows Flutter to make optimizations.

# Making Network Calls

## Importing Packages

Add two new imports at the top of main.dart:

```dart
import 'dart:convert';
import 'package:http/http.dart' as http;
```

Navigate to `pubspec.yaml` in the root folder of your project. In the dependencies section, add the following line (pay attention to the indentation):

```yaml
http: ^0.13.3
```

## Using Asynchronous Code

Dart apps are single-threaded, but Dart provides support for running code on other threads that doesn’t block the UI thread with the __async/await__ pattern.

Note: The code inside of __async__ methods all runs on the UI thread. It’s scheduled to run later, when the UI isn’t busy. If you want to run some code on another thread, then you’d need to create a new Dart __isolate__.

To make the asynchronous HTTP call, add `_loadData`:

```dart
var _members = <dynamic>[];
final _biggerFont = const TextStyle(fontSize: 18.0);

Future<void> _loadData() async {
  const dataUrl = 'https://api.github.com/orgs/raywenderlich/members';
  final response = await http.get(Uri.parse(dataUrl));
  setState(() {
    _members = json.decode(response.body) as List;
  });
}
```

Add an `initState` override to the stateful class:

```dart
@override
void initState() {
  super.initState();
  _loadData();
}
```

# Using a ListView

Dart provides a __ListView__ that lets you show the data in a list. `ListView` acts like a `RecyclerView` on Android or a `UICollectionView` on iOS.

Add `_buildRow`:

```dart
Widget _buildRow(int i) {
  return ListTile(
    title: Text('${_members[i]['login']}', style: _biggerFont),
  );
}
```

Replace the `body` line in the `build` method:

```dart
body: ListView.builder(
    padding: const EdgeInsets.all(16.0),
    itemCount: _members.length,
    itemBuilder: (BuildContext context, int position) {
      return _buildRow(position);
    }),
```

## Adding Dividers

To add dividers into the list, use `ListView.separated` instead of `ListView.builder`:

```dart
body: ListView.separated(
    itemCount: _members.length,
    itemBuilder: (BuildContext context, int position) {
      return _buildRow(position);
    },
    separatorBuilder: (context, index) {
      return const Divider();
    }),
```

To add padding to each row, wrap `ListTile` with `Padding` inside `_buildRow`:

```dart
Widget _buildRow(int i) {
  return Padding(
    padding: const EdgeInsets.all(16.0),
    child: ListTile(
      title: Text('${_members[i]['login']}', style: _biggerFont),
    ),
  );
}
```

# Parsing to Custom Types

Add a new `Member` type at the bottom of `main.dart`:

```dart
class Member {
  Member(this.login);
  final String login;
}
```

Update the `_members` declaration so that it’s a list of `Member` objects, then parse:

```dart
final _members = <Member>[];

setState(() {
  final dataList = json.decode(response.body) as List;
  for (final item in dataList) {
    final login = item['login'] as String? ?? '';
    final member = Member(login);
    _members.add(member);
  }
});
```

Replace the `title` line of `ListTile` with the following:

```dart
title: Text('${_members[i].login}', style: _biggerFont),
```

# Downloading Images With NetworkImage

Update `Member` to add an `avatarUrl` property. Then parse:

```dart
class Member {
  Member(this.login, this.avatarUrl);
  final String login;
  final String avatarUrl;
}

setState(() {
  final dataList = json.decode(response.body) as List;
  for (final item in dataList) {
    final login = item['login'] as String? ?? '';
    final url = item['avatar_url'] as String? ?? '';
    final member = Member(login, url);
    _members.add(member);
  }
});
```

Add it to your `ListTile`:

```dart
Widget _buildRow(int i) {
  return Padding(
    padding: const EdgeInsets.all(16.0),
    child: ListTile(
      title: Text('${_members[i].login}', style: _biggerFont),
      leading: CircleAvatar(
        backgroundColor: Colors.green,
        backgroundImage: NetworkImage(_members[i].avatarUrl),
      ),
    ),
  );
}
```

# Adding a Theme

In `main.dart`, add the `ThemeData` to `MaterialApp` widget:

```dart
import 'package:flutter/material.dart';
import 'ghflutter.dart';
import 'strings.dart' as strings;

void main() => runApp(const GHFlutterApp());

class GHFlutterApp extends StatelessWidget {
  const GHFlutterApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: strings.appTitle,
      theme: ThemeData(primaryColor: Colors.green.shade800), 
      home: const GHFlutter(),
    );
  }
}
```
