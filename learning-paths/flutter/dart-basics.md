# Intro

Flutter is an exciting UI toolkit from Google that lets you write apps for different platforms including iOS, Android, the web and more, all using one codebase. Flutter uses the Dart language.

# Getting Started

To get started quickly, use the open-source tool [DartPad](https://dartpad.dev/).

Can install the Dart SDK locally on a machine. One way to do so is to install the Flutter SDK as it will also install the Dart SDK.

To install the Dart SDK directly, visit https://dart.dev/get-dart.

# Why Dart?

Dart has many similarities to other languages such as Java, C#, Swift and Kotlin.

# Core Concepts

- Dart programs begin with a call to `main`.

```dart
void main() {
  
  }
```

- Some core concepts:
  - Variables, Comments and Data Types
  - Basic Dart Types
  - Operators
  - Strings
  - Immutability
  - Nullability
  - Condition and Break
  - For Loops

## Variables, Comments and Data Types

Variables hold the data that your program will work on.

```dart
var myAge = 35;  
```

### Comments

Text following `//` is a single-line comment, while text within `/* ... */` is a multi-line comment block.

```dart
// This is a single-line comment.

print(myAge); // This is also a single-line comment.

/*
 This is a multi-line comment block. This is useful for long
 comments that span several lines.
 */
```

### Data Types

Dart is __statically typed__, meaning that each variable in Dart has a type that must be known when you compile the code. (contrasts with languages like Python and JavaScript, which are __dynamically typed__ => variables can hold different kinds of data when running the program)

If you don't explicitly specify a data type, Dart uses type inference to try to determine it. For example of enter a variable, `pi`, equal to 3.14 => Dart infers `pi` to be a `double`:

```dart
var pi = 3.14;

print(pi); // 3.14
```

### Basic Dart Types

- __int__: Integers
- __double__: Floating-point numbers
- __bool__: Booleans
- __String__: Sequences of characters

`int` and `double` both derive from a type named `num`. `num` uses the dynamic keyword to mimic dynamic typing in the statically typed Dart. Do this by replacing var with the type you want to use:

```dart
int yourAge = 27;

print(yourAge); // 27
```

### The Dynamic Keyword

If you use the `dynamic` keyword instead of `var`, you get what's effectively a dynamically typed variable:

```dart
dynamic numberOfKittens;

numberOfKittens = 'There are no kittens!';

print(numberOfKittens); // There are no kittens!

numberOfKittens = 0;

print(numberOfKittens); // 0

numberOfKittens = 0.5;

print(numberOfKittens); // 0.5
```

=> No error assigning different types.

### Booleans

The `bool` type holds values of either true or false.

```dart
bool areThereKittens = false;

print(areThereKittens); // false
```

### Strings

Can embed the value of an expression inside a string by using the dollar sign symbol: ${expression}.

```dart
var physicist = "$firstName $lastName likes the number ${84 / 2}";

print(physicist); // Albert Einstein
```

### Escaping Strings

Use `\n` for a new line. If there are special characters in the string, use `\` to escape them:

```dart
var quote = 'If you can\'t explain it simply\nyou don\'t understand it well enough.';

print(quote);

// If you can't explain it simply

// you don't understand it well enough.
```

If need to show escape sequences within the string, you can use raw strings, which are prefixed by r.

```dart
var rawString = r"If you can't explain it simply\nyou don't understand it well enough.";

print(rawString); 

// If you can't explain it simply\nyou don't understand it well enough.
```

## Operators

Some examples of Dart's operators include:

- arithmetic
- equality
- increment and decrement
- comparison
- logical

### Arithmetic Operators

For division, even with integers, Dart infers the resulting variable to be a double. That's why you get 42.0 instead of 42 for the last print statement.

```dart
print(40 + 2); // 42

print(44 - 2); // 42

print(21 * 2); // 42

print(84 / 2); // 42.0
```

### Equality Operators

```dart
print(42 == 43); // false

print(42 != 43); // true
```

### Comparison Operators

```dart
print(42 < 43); // true print(42 >= 43); // false
```

In addition, it also uses the usual compound arithmetic/assignment operators:

```dart
var value = 42.0;

value += 1; print(value); // 43.0

value -= 1; print(value); // 42.0

value *= 2; print(value); // 84.0

value /= 2; print(value); // 42.0
```

A shortened form of `+= 1` is `++`:

```dart
value++;

print(value); // 43.0
```

Has the usual modulo operator (%) to return the remainder after one number has been divided by another:

```dart
print(392 % 50); // 42
```

### Logical Operators

`&&` for __AND__ and `||` for __OR__.

```dart
print((41 < 42) && (42 < 43)); // true

print((41 < 42) || (42 > 43)); // true
```

The negation operator is the exclamation mark, which turns false to true and true to false.

```dart
print(!(41 < 42)); // false
```

### Null-Aware Operators

The double-question-mark operator, `??`, is like the Elvis operator in Kotlin: It returns the left-hand operand if the object isn't null. Otherwise, it returns the right-hand value:

```dart
String? middleName;

var name = middleName ?? 'none';

print(name); // none
```

The `?.` operator returns null if the object itself is null. Otherwise, it returns the value of the property on the right-hand side:

```dart
print(middleName?.length); // null
```

## Immutability

Dart uses the keywords `const` and `final` for values that don't change:
- Use `const` for values that are known at compile-time. 
- Use `final` for values that don't have to be known at compile-time but cannot be reassigned after being initialized.

Can use `const` and `final` in place of `var` and let type inference determine the type.

## Nullability

To tell Dart that you want to allow the value `null`, add `?` after the type.

```dart
String? middleName = null;

print(middleName); // null
```

## Control Flow

Let you dictate when to execute, skip over or repeat certain lines of code:

- Conditionals
- While Loops
- Continue and Break
- For Loops

### Conditionals

Simple `if/else` statements.

### While Loops

Two forms of while loops in Dart: `while` and `do-while`.

```dart
i = 1;
do {
  print(i);
  i++;
} while (i < 10);
// 1
// 2
// 3
// 4
// 5
// 6
// 7
// 8
// 9
```

### Continue and Break

- __continue__: Skips remaining code inside a loop and immediately goes to the next iteration.
- __break__: Stops the loop and continues execution after the body of the loop.

### For Loops

Dart also offers a `for-in` loop, which iterates over a collection of objects.

```dart
for (final dessert in desserts) {
  print('I love to eat $dessert.');
}
// I love to eat cookies.
// I love to eat cupcakes.
// I love to eat pie.
// I love to eat cake.
```

## Collections

Dart includes several different types of collections, but the two most common ones are: `List` and `Map`. 

### Lists

```dart
List desserts = ['cookies', 'cupcakes', 'donuts', 'pie'];
```

### Maps

```dart
Map<String, int> calories = {
  'cake': 500,
  'donuts': 150,
  'cookies': 100,
};
```

## Functions

- Return type
- Function name
- Parameter list in parentheses
- Function body enclosed in brackets

### Defining Functions

```dart
bool isBanana(String fruit) {
  return fruit == 'banana';
}

```

### Nesting Functions

```dart
void main() {
  bool isBanana(String fruit) {
    return fruit == 'banana';
  }

  var fruit = 'apple';
  print(isBanana(fruit)); // false
}
```

### Optional Parameters

```dart
String fullName(String first, String last, [String? title]) {
  if (title == null) {
    return '$first $last';
  } else {
    return '$title $first $last';
  }
}
```

Now, you can call the function with or without the optional parameter:

```dart
print(fullName('Joe', 'Howard'));
// Joe Howard

print(fullName('Albert', 'Einstein', 'Professor'));
// Professor Albert Einstein
```

### Named Parameters and Default Values

__named parameters__, which you get by surrounding the parameter list with curly brackets: `{ }`. These parameters are optional by default, but you can give them default values or make them required by using the required keyword:

```dart
bool withinTolerance({required int value, int min = 0, int max = 10}) {
  return min <= value && value <= max;
}
```

=> `value` is required, while `min` and `max` are optional with default values.

## Anonymous Functions

Dart supports __first-class functions__, meaning that it treats functions like any other data type. You can assign them to variables, pass them as arguments and return them from other functions.

Can simplify functions whose body only contains a single line by using arrow syntax. To do this, remove the curly brackets and add a fat arrow `=>`.

```dart
// original anonymous function
final onPressed = () {
  print('button pressed');
};

// refactored
final onPressed = () => print('button pressed');
```

You'll often see anonymous functions when:
- passed around as callbacks for UI events.
- with collections.

```dart
// 1
final drinks = ['water', 'juice', 'milk'];
// 2
final bigDrinks = drinks.map(
  // 3
  (drink) => drink.toUpperCase()
);
// 4
print(bigDrinks); // (WATER, JUICE, MILK)
```
