# Intro

Use the [test](https://pub.dev/packages/test) package provides the core framework for writing unit tests, and the [flutter_test](https://api.flutter.dev/flutter/flutter_test/flutter_test-library.html) package provides additional utilities for testing widgets.

# Getting started with test package

To add the `test` package as a dev dependency, run `flutter pub add`:

```bash
 $ flutter pub add dev:test
 ```

Create a sample `Counter` class for testing:

```dart
class Counter {
  int value = 0;

  void increment() => value++;

  void decrement() => value--;
}
```

Combine some unit tests with `group`:

```dart
import 'package:counter_app/counter.dart';
import 'package:test/test.dart';

void main() {
  group('Counter', () {
    test('value should start at 0', () {
      expect(Counter().value, 0);
    });

    test('value should be incremented', () {
      final counter = Counter();

      counter.increment();

      expect(counter.value, 1);
    });

    test('value should be decremented', () {
      final counter = Counter();

      counter.decrement();

      expect(counter.value, -1);
    });
  });
}
```

Run tests:

1. using IntelliJ or VSCode
  - IntelliJ
    - Open the counter_test.dart file
    - Select the Run menu
    - Click the Run 'tests in counter_test.dart' option
    - Alternatively, use the appropriate keyboard shortcut for your platform.
  - VSCode
    - Open the counter_test.dart file
    - Select the Run menu
    - Click the Start Debugging option
    - Alternatively, use the appropriate keyboard shortcut for your platform.

2. Terminal 

```bash
$ flutter test test/counter_test.dart
```
