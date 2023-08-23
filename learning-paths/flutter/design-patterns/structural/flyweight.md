# Definition

Save and use memory efficiently, increase performance by avoiding data duplication. Objects that have identical data can share that data instead of copying it everywhere it's needed.

# Example code

```dart
class EnemyType {
  final String name;
  final ByteData imageData; // This attribute is of substantial size, so need to save memory space by not repeating it unnecessarily

  const EnemyType(this.name, this.imageData);
}

// Remove the extrinsic state from the Enemy class and add a cache for the flyweight objects
class Enemy {
  static final Map<String, EnemyType> types = {};

  final EnemyType type;
  int x;
  int y;

  Enemy(String typeName) : type = getType(typeName);

  void moveTo(int x, int y) {
    this.x = x;
    this.y = y;
  }

  void draw() {
    print("Drawing ${type.name}...");
  }

  static EnemyType getType(String typeName) {
    return types.putIfAbsent(typeName, () => EnemyType(
      typeName, 
      loadImageData(typeName),
    ));
  }
}

// Then, when creating Enemy class, only a single instance of an Enemy with the EnemyType - `Red Avenger` will be constructed regardless how many items of that type in the list
final List<Enemy> enemies = [
  Enemy("Red Avenger"),
  Enemy("Red Avenger"),
  Enemy("Blue Stinger"),
];
```

- Within the context of the pattern, the memory-hogging constant data is referred to as __intrinsic__ state, data that every object of a given type needs access to in an unaltered form. 
- Each object's mutable data is known as the __extrinsic__ state, because it's often changed by events occurring outside the instance and may be unique to a given instance.
