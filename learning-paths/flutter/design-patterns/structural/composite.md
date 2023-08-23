# Definition

Create part-whole hierarchies, tree structures in which individual objects and compositions of those objects can be treated uniformly.

# Example code

```dart
class Item {
  final double price;
  final double weight;

  const Item(this.price, this.weight);
}

class Container implements Item {
  final List<Item> items = [];

  void addItem(Item item) => items.add(item);

  double get price =>
      items.fold(0, (double sum, Item item) => sum + item.price);

  double get weight =>
      items.fold(0, (double sum, Item item) => sum + item.weight);
}

// Create the hierarchy of objects
final container1 = Container()
  ..addItem(Item(5.95, 1.5))
  ..addItem(Item(9.99, 2))
  ..addItem(Item(25, 2.3));

final container2 = Container()
  ..addItem(Item(16.5, 9));

container1.addItem(container2);

print("Price: ${container1.price}");
print("Weight: ${container1.weight}");
```

Illustrative graph:

![Screenshot 2023-08-23 at 11 21 12](https://github.com/minhnimble/learning-notes/assets/70877098/42e59e16-caaf-4629-93d8-3642f4305c84)
