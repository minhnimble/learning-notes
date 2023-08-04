# Intro

The very thumb rule:

`Constraints go down. Sizes go up. Parent sets position.`

- A widget gets its own constraints from its parent. A constraint is just a set of 4 doubles: a minimum and maximum width, and a minimum and maximum height.
- Then the widget goes through its own list of children. One by one, the widget tells its children what their constraints are (which can be different for each child), and then asks each child what size it wants to be.
- After that, the widget positions its children (horizontally in the x axis, and vertically in the y axis), one by one.
- Finally, the widget tells its parent about its own size (within the original constraints, of course).

# Limitation

Flutter's layout engine is designed to be a one-pass process with some limitations:
- A widget can decide its own size only within the constraints given to it by its parent. This means a widget usually __can’t have any size it wants__.
- A widget __can’t know and doesn’t decide its own position in the screen__, the widget’s parent does.
- __It’s impossible to precisely define the size and position of any widget__ without taking into consideration the tree as a whole.
- __Be specific when defining alignment__. If a child wants a different size from its parent and the parent doesn’t have enough information to align it, then the child’s size might be ignored.

Widgets are rendered by their underlying [RenderBox](https://api.flutter.dev/flutter/rendering/RenderBox-class.html) objects. There are __five__ kinds of boxes, in terms of how they handle their constraints:
- As big as possible, e.g., the boxes used by `Center` and `ListView`.
- The same size as their children, e.g., the boxes used by `Transform` and `Opacity`.
- Try to be a particular size, e.g., the boxes used by `Image` and `Text`.
- Vary from type to type based on their constructor arguments, e.g., `Container` constructor defaults to trying to be as big as possible, but if it is given it a `width`, it tries to honor that and be that particular size.
- Vary based on the constraints they are given e.g., `Row` and `Column` (flex boxes).