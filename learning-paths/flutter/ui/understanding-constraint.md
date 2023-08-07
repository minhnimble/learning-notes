# Intro

The very thumb rule:

`Constraints go down. Sizes go up. Parent sets position.`

- A widget gets its own constraints from its parent. A constraint is just a set of 4 doubles: a minimum and maximum width, and a minimum and maximum height.
- Then the widget goes through its own list of children. One by one, the widget tells its children what their constraints are (which can be different for each child), and then asks each child what size it wants to be.
- After that, the widget positions its children (horizontally in the x axis, and vertically in the y axis), one by one.
- Finally, the widget tells its parent about its own size (within the original constraints, of course).

# Limitation

Flutter's layout engine is designed to be a one-pass process with some limitations:
- A widget can decide its own size only within the constraints given to it by its parent. This means a widget usually __can't have any size it wants__.
- A widget __can't know and doesn't decide its own position in the screen__, the widget's parent does.
- __It's impossible to precisely define the size and position of any widget__ without taking into consideration the tree as a whole.
- __Be specific when defining alignment__. If a child wants a different size from its parent and the parent doesn't have enough information to align it, then the child's size might be ignored.

Widgets are rendered by their underlying [RenderBox](https://api.flutter.dev/flutter/rendering/RenderBox-class.html) objects. There are __five__ kinds of boxes, in terms of how they handle their constraints:
- As big as possible, e.g., the boxes used by `Center` and `ListView`.
- The same size as their children, e.g., the boxes used by `Transform` and `Opacity`.
- Try to be a particular size, e.g., the boxes used by `Image` and `Text`.
- Vary from type to type based on their constructor arguments, e.g., `Container` constructor defaults to trying to be as big as possible, but if it is given it a `width`, it tries to honor that and be that particular size.
- Vary based on the constraints they are given e.g., `Row` and `Column` (flex boxes).

Examples: [GitHub repo](https://github.com/marcglasberg/flutter_layout_article).

# Tight vs loose constraints

## Tight constraint

Offers a single possibility, an exact size. It has its maximum width equal to its minimum width; and has its maximum height equal to its minimum height. For example:
- The `App` widget, which is contained by the [RenderView](https://api.flutter.dev/flutter/rendering/RenderView-class.html) class. The box used by the child is given a constraint that forces it to exactly fill the application's content area (typically, the entire screen).

## Loose constraint

Is one that has a minimum of zero and a maximum non-zero. It means the maximum is maintained but the minimum is removed, so the widget can have a __minimum__ width and height both equal to zero. For example:
- `Center`'s purpose is to transform the tight constraints it received from its parent (the screen) to loose constraints for its child (the `Container`).

# Unbounded constraints

In certain situations, a box's constraint is infinite. It means that either the maximum width or the maximum height is set to `double.infinity`. For example:
- [ListView](https://api.flutter.dev/flutter/widgets/ListView-class.html)  tries to expand to fit the space available in its cross-direction, i.e., it's a vertically-scrolling block and tries to be as wide as its parent. If you nest a vertically scrolling `ListView` inside a horizontally scrolling `ListView`, the inner list tries to be as wide as possible, which is infinitely wide, since the outer one is scrollable in that direction.

=> A box that is as big as possible won't function usefully when given an unbounded constraint and, in debug mode, throws an __exception__.

# Flex

- With a bounded constraint in its primary direction, it tries to be as big as possible.

- With a unbounded constraint in its primary direction, it tries to fit its children in that space. Each child's flex value must be set to zero, meaning that [Expanded](https://api.flutter.dev/flutter/widgets/Expanded-class.html) can't be used when the flex box is inside another flex box or a scrollable; otherwise it throws an exception.

- The cross direction (width for [Column](https://api.flutter.dev/flutter/widgets/Column-class.html) or height for [Row](https://api.flutter.dev/flutter/widgets/Row-class.html)), must never be unbounded, or it can't reasonably align its children.
