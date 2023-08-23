# Definition

Attach new behavior or attributes to an object by wrapping it in a special decorator that shares the object's interface.

# Example code

```dart
abstract class Shape {
  String draw();
}

class Square implements Shape {
  String draw() => "Square";
}

class Triangle implements Shape {
  String draw() => "Triangle";
}

// Define the Decorator interface
abstract class ShapeDecorator implements Shape {
  final Shape shape;

  ShapeDecorator(this.shape);

  String draw();
}

class GreenShapeDecorator extends ShapeDecorator {
  GreenShapeDecorator(Shape shape) : super(shape);

  @override
  String draw() => "Green ${shape.draw()}";
}

class BlueShapeDecorator extends ShapeDecorator {
  BlueShapeDecorator(Shape shape) : super(shape);

  @override
  String draw() => "Blue ${shape.draw()}";
}

// Usage
final square = Square();
print(square.draw());

final greenSquare = GreenShapeDecorator(square);
print(greenSquare.draw());

final blueGreenSquare = BlueShapeDecorator(greenSquare);
print(blueGreenSquare.draw());
```
