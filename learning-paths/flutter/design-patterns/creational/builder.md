# Definition

Constructing objects data models. It can be used to keep the details of constructing an object separated from its final representation.

# Example code

```dart
enum PizzaSize {
  S,
  M,
  L,
  XL,
}

enum PizzaSauce {
  none,
  marinara,
  garlic,
}

enum PizzaCrust {
  classic,
  deepDish,
}

class Pizza {
  final PizzaSize size;
  final PizzaCrust crust;
  final PizzaSauce sauce;
  final List<String> toppings;
  final bool hasExtraCheese;
  final bool hasDoubleMeat;
  final String notes;

  Pizza({
    this.size,
    this.crust,
    this.sauce,
    this.toppings,
    this.hasExtraCheese = false,
    this.hasDoubleMeat = false,
    this.notes
  });

  Pizza copyWith({
    PizzaSize size,
    PizzaCrust crust,
    PizzaSauce sauce,
    List<String> toppings,
    bool hasExtraCheese,
    bool hasDoubleMeat,
    String notes
  }) {
    return Pizza(
      size: size ?? this.size,
      crust: crust ?? this.crust,
      sauce: sauce ?? this.sauce,
      toppings: toppings ?? this.toppings,
      hasExtraCheese: hasExtraCheese ?? this.hasExtraCheese,
      hasDoubleMeat: hasDoubleMeat ?? this.hasDoubleMeat,
      notes: notes ?? this.notes
    );
  }
}
```

- All the properties in this model are marked `final`, which keeps them from being unexpectedly modified.
- `copyWith()` method enables you to make immutable copies of the model, only modifying values that are passed into the method.
