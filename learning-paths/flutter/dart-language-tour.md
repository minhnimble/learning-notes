# Intro

For coverage of Dart's core libraries, check out the library tour: https://dart.dev/guides/libraries/library-tour.

For a more hands-on introduction, visit the Dart cheatsheet codelab: https://dart.dev/codelabs/dart-cheatsheet.

## Variables

Dart code is in type-safe: https://dart.dev/language/type-system

## Control flow statements

### Switch statements

Use a `default` or wildcard `_` clause to execute code when no case clause matches:

```dart
var command = 'OPEN';
switch (command) {
  case 'APPROVED':
    executeApproved();
  case 'DENIED':
    executeDenied();
  case 'OPEN':
    executeOpen();
  default:
    executeUnknown();
}

switch (record) {
  case (int _, String _):
    print('First field is int and second is String.');
}
```

### Assert

During development, use an assert statement — `assert(<condition>, <optionalMessage>);` — to disrupt normal execution if a boolean condition is false.

```dart
assert(urlString.startsWith('https'),
    'URL ($urlString) should start with "https".');

```

## Functions

A shorthand `=>` (arrow) syntax is handy for functions that contain a single statement or for passing anonymous functions as arguments:

```dart
flybyObjects.where((name) => name.contains('turn')).forEach(print);
```

## Imports

Read about libraries and visibility in Dart, including library prefixes, show and hide, and lazy loading through the deferred keyword. Ref: https://dart.dev/language/libraries

## Class

Read about classes in Dart, including initializer lists, optional new and const, redirecting constructors, factory constructors, getters, setters, etc. Ref: https://dart.dev/language/classes

## Enums

An example of an enhanced enum declaration, with a defined set of constant instances:

```dart
/// Enum that enumerates the different planets in our solar system
/// and some of their properties.
enum Planet {
  mercury(planetType: PlanetType.terrestrial, moons: 0, hasRings: false),
  venus(planetType: PlanetType.terrestrial, moons: 0, hasRings: false),
  // ···
  uranus(planetType: PlanetType.ice, moons: 27, hasRings: true),
  neptune(planetType: PlanetType.ice, moons: 14, hasRings: true);

  /// A constant generating constructor
  const Planet(
      {required this.planetType, required this.moons, required this.hasRings});

  /// All instance variables are final
  final PlanetType planetType;
  final int moons;
  final bool hasRings;

  /// Enhanced enums support getters and other methods
  bool get isGiant =>
      planetType == PlanetType.gas || planetType == PlanetType.ice;
}

// Usage
final yourPlanet = Planet.earth;

if (!yourPlanet.isGiant) {
  print('Your planet is not a "giant planet".');
}
```

## Inheritance

Dart has single inheritance. Ref: https://dart.dev/language/extend

```dart
class Orbiter extends Spacecraft {
  double altitude;

  Orbiter(super.name, DateTime super.launchDate, this.altitude);
}
```

## Mixins

Mixins are a way of reusing code in multiple class hierarchies. Ref: https://dart.dev/language/mixins


```dart
mixin Piloted {
  int astronauts = 1;

  void describeCrew() {
    print('Number of astronauts: $astronauts');
  }
}

// Usage
class PilotedCraft extends Spacecraft with Piloted {
  // ···
}
```

## Interfaces and abstract classes

### Interface

Every class implicitly defines an interface containing all the instance members of the class and of any interfaces it implements.

A class implements one or more interfaces by declaring them in an `implements` clause and then providing the APIs required by the interfaces. For example:

```dart
class MockSpaceship implements Spacecraft {
  // ···
}
```

To define an interface, use the interface modifier.

```dart
// Library a.dart
interface class Vehicle {
  void moveForward(int meters) {
    // ...
  }
}
```

The goal is to guarantees:
- When one of the class's instance methods calls another instance method on `this`, it will always invoke a known implementation of the method from the same library.
- Other libraries can't override methods that the interface class's own methods might later call in unexpected ways. This reduces the [fragile base class problem](https://en.wikipedia.org/wiki/Fragile_base_class).

```dart
// Library b.dart
import 'a.dart';

// Can be constructed
Vehicle myVehicle = Vehicle();

// ERROR: Cannot be inherited
class Car extends Vehicle {
  int passengers = 4;
  // ...
}

// Can be implemented
class MockVehicle implements Vehicle {
  @override
  void moveForward(int meters) {
    // ...
  }
}
```

### Abstract class

An abstract class can be used to be extended (or implemented) by a concrete class. Abstract classes can contain abstract methods (with empty bodies).

```dart
// Library a.dart
abstract class Vehicle {
  void moveForward(int meters);

  void MoveForwardInHighSpeed(int meters) {
    print('====High=====');
    moveForward(meters);
    print('====Speed=====');
  }
}
```

Abstract classes cannot be constructed from any library, whether its own or an outside library. 

```dart


// Library b.dart
import 'a.dart';

// Error: Cannot be constructed
Vehicle myVehicle = Vehicle();

// Can be extended
class Car extends Vehicle {
  int passengers = 4;
  // ···
}

// Can be implemented
class MockVehicle implements Vehicle {
  @override
  void moveForward(int meters) {
    // ...
  }
}
```

## Async

Avoid callback hell and make your code much more readable by using `async` and `await`.

```dart
const oneSecond = Duration(seconds: 1);
// ···
Future<void> printWithDelay(String message) async {
  await Future.delayed(oneSecond);
  print(message);
}
```

Use `async*`, which gives you a nice, readable way to build streams.

```dart
Stream<String> report(Spacecraft craft, Iterable<String> objects) async* {
  for (final object in objects) {
    await Future.delayed(oneSecond);
    yield '${craft.name} flies by $object';
  }
}
```

Read about advanced asynchrony support, including async functions, Future, Stream, and the asynchronous loop (await for). Ref: https://dart.dev/language/async

## Exceptions

To raise an exception, use `throw`:

```dart
if (astronauts == 0) {
  throw StateError('No astronauts.');
}
```

To catch an exception, use a try statement with on or catch (or both):

```dart
Future<void> describeFlybyObjects(List<String> flybyObjects) async {
  try {
    for (final object in flybyObjects) {
      var description = await File('$object.txt').readAsString();
      print(description);
    }
  } on IOException catch (e) {
    print('Could not describe object: $e');
  } finally {
    flybyObjects.clear();
  }
}
```

Read about exceptions, including stack traces, `rethrow`, and the difference between `Error` and `Exception`. Ref: https://dart.dev/language/error-handling#exceptions

## Important concepts

- Everything you can place in a variable is an object, and every object is an instance of a class.
- Numbers, functions, and null are objects. 
- Type annotations are optional because Dart can infer types.
- When you want to explicitly say that any type is allowed, use the type `Object?` (if you've enabled null safety), or `Object`.
- Dart doesn't have the keywords public, protected, and private. Ref: https://dart.dev/language/libraries.
- Identifiers can start with a letter or underscore `_` (private to its library), followed by any combination of those characters plus digits.
