# Intro

The core of Flutter's layout mechanism is widgets. 
- Widgets are classes used to build UIs.
- Widgets are used for both layout and UI elements.
- Compose simple widgets to build complex widgets.

[Container](https://api.flutter.dev/flutter/widgets/Container-class.html) is a widget class that allows you to customize its child widget. Use a Container when you want to add padding, margins, borders, or background color, to name some of its capabilities.

# Lay out a widget

## Visible widget

[Text](https://api.flutter.dev/flutter/widgets/Text-class.html) widget:

```dart
Text('Hello World'),
```

[Image](https://api.flutter.dev/flutter/widgets/Image-class.html) widget:

```dart
Image.asset(
  'images/lake.jpg',
  fit: BoxFit.cover,
),
```

[Icon](https://api.flutter.dev/flutter/material/Icons-class.html) widget:

```dart
Icon(
  Icons.star,
  color: Colors.red[500],
),
```

All layout widgets have either of the following:

- A `child` property if they take a single child—for example, `Center` or `Container`
- A `children` property if they take a list of widgets—for example, `Row`, `Column`, `ListView`, or `Stack`.

## Add the layout widget to the page

A Flutter app is itself a `widget`, and most widgets have a `build()` method.

### Material app

For a `Material` app, you can use a [Scaffold](https://api.flutter.dev/flutter/material/Scaffold-class.html) widget. It provides: 
- a default banner
- background color
- has API for adding:
  - drawers 
  - snack bars
  - bottom sheets

```dart
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter layout demo',
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Flutter layout demo'),
        ),
        body: const Center(
          child: Text('Hello World'),
        ),
      ),
    );
  }
}
```

When designing your UI, you can exclusively use widgets from the standard [widgets library](https://api.flutter.dev/flutter/widgets/widgets-library.html), or you can use widgets from the [Material library](https://api.flutter.dev/flutter/material/material-library.html).

### Non-material app

```dart
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(color: Colors.white),
      child: const Center(
        child: Text(
          'Hello World',
          textDirection: TextDirection.ltr,
          style: TextStyle(
            fontSize: 32,
            color: Colors.black87,
          ),
        ),
      ),
    );
  }
}
```

Non-Material app doesn't include an `AppBar`, title, or background color. If you want these features in a non-Material app, you have to build them yourself.

## Lay out multiple widgets vertically and horizontally

- `Row` and `Column` are two of the most commonly used layout patterns.
- `Row` and `Column` each take a list of child widgets.
- A child widget can itself be a `Row`, `Column`, or other complex widget.
- You can specify how a `Row` or `Column` aligns its children, both vertically and horizontally.
- You can stretch or constrain specific child widgets.
- You can specify how child widgets use the `Row`'s or `Column`'s available space.

![Screenshot 2023-07-28 at 15 15 23](https://github.com/minhnimble/learning-notes/assets/70877098/350d2983-b522-4f2a-90fe-224f98ac56cf)

Flutter also offers specialized, higher level widgets that might be sufficient for your needs like:
- Instead of `Row`, [ListTile](https://api.flutter.dev/flutter/material/ListTile-class.html) is an widget with properties for leading and trailing icons, and up to 3 lines of text. 
- Instead of Column, [ListView](https://api.flutter.dev/flutter/widgets/ListView-class.html), is a column-like layout that automatically scrolls if its content is too long to fit the available space. 

For more information, see [Common layout widgets](https://docs.flutter.dev/ui/layout#common-layout-widgets).

## Aligning

Control how a `row` or `column` aligns its children using the `mainAxisAlignment` and `crossAxisAlignment` properties. 

The [MainAxisAlignment](https://api.flutter.dev/flutter/rendering/MainAxisAlignment.html) and [CrossAxisAlignment](https://api.flutter.dev/flutter/rendering/CrossAxisAlignment.html) enums offer a variety of constants for controlling alignment.

`spaceEvenly` divides the free space evenly between, before, and after each widget.

## Sizing

Widgets can be sized to fit within a row or column by using the [Expanded](https://api.flutter.dev/flutter/widgets/Expanded-class.html) widget.

Use the `Expanded` widget `flex` property, an integer that determines the flex factor (default to 1) for a widget, to allow a widget to occupy the space as `n` times as its siblings. For example we want to occupy twice as much, set `flex` to 2:

```dart
Row(
  crossAxisAlignment: CrossAxisAlignment.center,
  children: [
    Expanded(
      child: Image.asset('images/pic1.jpg'),
    ),
    Expanded(
      flex: 2,
      child: Image.asset('images/pic2.jpg'),
    ),
    Expanded(
      child: Image.asset('images/pic3.jpg'),
    ),
  ],
);
```

## Package

By default, a row or column occupies as much space along its main axis as possible.

To pack the children closely together, set its `mainAxisSize` to `MainAxisSize.min`.

## Nesting rows and columns

To minimize the visual confusion that can result from heavily nested layout code, implement pieces of the UI in variables and functions.


## Images handling

- When add images, update the `pubspec.yaml` file to access them -> see this example's [pubspec.yaml file](https://github.com/flutter/website/tree/main/examples/layout/row_column/pubspec.yaml) or [Adding assets and images](https://docs.flutter.dev/ui/assets/assets-and-images).
- When referencing online images using `Image.network`, don't need to do anything.

The [Pavlova image](https://pixabay.com/en/photos/pavlova) runs best horizontally on a wide device, such as a tablet. App source: [pavlova](https://github.com/flutter/website/tree/main/examples/layout/pavlova)

# Common layout widgets

## Standard

- [Container](https://docs.flutter.dev/ui/layout#container): Adds padding, margins, borders, background color, or other decorations to a widget. => [Demo](https://github.com/flutter/website/tree/main/examples/layout/container)
  - Contains a single child widget, but that child can be a Row, Column, or even the root of a widget tree.
- [GridView](https://docs.flutter.dev/ui/layout#gridview): Lays widgets out as a scrollable grid. => [Demo](https://github.com/flutter/gallery/tree/main/lib/demos/material/grid_list_demo.dart)
  - Detects when the column content exceeds the render box and automatically provides scrolling.
  - Build your own custom grid, or use one of the provided grids:
    - `GridView.count` allows you to specify the number of columns.
    - `GridView.extent` allows you to specify the maximum pixel width of a tile.
- [ListView](https://docs.flutter.dev/ui/layout#listview): Lays widgets out as a scrollable list => [Demo](https://github.com/flutter/gallery/tree/main/lib/demos/reference/colors_demo.dart)
  - A specialized `Column` for organizing a list of boxes.
  - Can be laid out horizontally or vertically.
  - Detects when its content won't fit and provides scrolling.
  - Less configurable than `Column`, but easier to use and supports scrolling.
- [Stack](https://docs.flutter.dev/ui/layout#stack): Overlaps a widget on top of another. => [Demo](https://github.com/flutter/gallery/tree/main/lib/demos/material/bottom_navigation_demo.dart)
  - The first widget in the list of children is the base widget; subsequent children are overlaid on top of that base widget
  - A `Stack`’s content can’t scroll.
  - can clip children that exceed the render box.

## Material

- [Card](https://docs.flutter.dev/ui/layout#card): Organizes related info into a box with rounded corners and a drop shadow. => [Demo](https://github.com/flutter/gallery/tree/main/lib/demos/material/cards_demo.dart)
  - Used for presenting related nuggets of information.
  - Accepts a single child, but that child can be a Row, Column, or other widget that holds a list of children.
  - Displayed with rounded corners and a drop shadow.
  - A Card’s content can’t scroll.
- [ListTile](https://docs.flutter.dev/ui/layout#listtile): Organizes up to 3 lines of text, and optional leading and trailing icons, into a row. => [Demo](https://github.com/flutter/gallery/tree/main/lib/demos/material/list_demo.dart)
  - A specialized row that contains up to 3 lines of text and optional icons.
  - Less configurable than Row, but easier to use.
