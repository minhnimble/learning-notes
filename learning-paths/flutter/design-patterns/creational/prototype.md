# Definition

Making an object responsible for its own cloning. Code outside an object can make a copy by creating an empty new instance and copying each property over one at a time, but if an object includes its own cloning method, private properties won't be missed, and only the object itself needs to be aware of its internal structure.

# Example code

```dart
class Point {
  final int x;
  final int y;

  const Point(this.x, this.y);
  
  Point copyWith({int x, int y}) {
    return Point(
      x ?? this.x,
      y ?? this.y,
    );
  }

  Point clone() => copyWith(x: x, y: y);
}

final p1 = Point(5, 8);
final p2 = p1.clone();
```

→ The `clone()` method can use `copyWith()` to produce a full object copy, preventing us from having to define a separate process for cloning.
