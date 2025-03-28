# Object-oriented programming

Ruby is, like many other popular languages, an object-oriented programming language.

> [!NOTE]
> Classes are like ideas, objects are concrete things, manifestations of their ideas.

# Variables (Skip reuse section as it was obvious)

- **Variables** assign names to objects for easy reference.
- Use the **assignment operator (`=`)** to assign names.
- A variable is just a **name** for an object, not the object itself.
- **Use meaningful names** to reflect the object’s purpose. Avoid generic or misleading names.
- Ruby evaluates the expression on the right first.

# Built-In Data Types

## Numbers

- A number is defined by a series of digits, using a dot as a decimal mark, and optinally an underscore as a thousands separator.
- Mathematical operations result in a floating point number except if all numbers used are integer numbers.
- Use floating point (decimal) numbers when doing devisions for correct result instead of rounded integer one.

## String

- Strings can be defined by enclosing any text with single or double quotes.
- Examples of :calling methods on objects that are Strings:
```ruby
> "hello".upcase
=> "HELLO"

> "hello".capitalize
=> "Hello"

> "hello".length
=> 5

> "hello".reverse
=> "olleh"
```

## True, False, and Nil

- The object true represents “truth”, while false represents the opposite of it.
- The object nil represents “nothing”.

## Symbols

- A symbol is created by adding a colon in front of a word.
- When to use strings, and when to use symbols:
  - if the text at hand is “data”, then use a string. If it’s code, then use a symbol, especially when used as keys in hashes.
  - While strings represent data that can change, symbols represent unique values and identifiers, like numbers, or bar codes, which are static. 
- Symbols are a special, limited variation of Strings.
```ruby
# String
$ irb
> "a string".object_id
=> 70358630335100
> "a string".object_id
=> 70358640625960

#Symbol
> :a_symbol.object_id
=> 1086748
> :a_symbol.object_id
=> 1086748
```

## Array

- Arrays have a defined order, and can store all kinds of objects.  ```["A string", 1, true, :symbol, 2]```
- To add an element to the end of an existing Array (appended) you can use the operator `<<`, called “shovel operator”,
- `first` and `last` are alternative ways to retrieve the first and last element, and some other things that you can do with Arrays:
```ruby
$ irb
> [1, 2, 3].first
1
> [1, 2, 3].last
3

> [1, 2, 3].length
=> 3

> [3, 1, 2].sort
=> [1, 2, 3]

> [1, nil, 2, 3, nil].compact
=> [1, 2, 3]

> [1, 2, 3].index(3)
=> 2

> [1, 2, 3, 4].rotate(2)
=> [3, 4, 1, 2]

> [[1, 2, 3], [4, 5, 6], [7, 8, 9]].transpose
=> [[1, 4, 7], [2, 5, 8], [3, 6, 9]]
```

# Hashes

- A Hash assigns values to keys with `=>`, so that values can be looked up by their key (old-style):
```ruby
dictionary = { "one" => "eins", "two" => "zwei", "three" => "drei" }
dictionary["zero"] = "null"
puts dictionary["zero"]
```
- Hashes can use any kind of objects as keys and values.
- merge two Hashes:
```ruby
$ irb
> { "one" => "eins" }.merge({ "two" => "zwei" })
=> { "one" => "eins", "two" => "zwei" }
```
- `fetch` does just the same as the square bracket lookup [], but it will raise an error if the key is not defined:
```ruby
$ irb
> dictionary = { "one" => "eins" }
> dictionary.fetch("one")
=> "eins"
> dictionary.fetch("two")
KeyError: key not found: "two"
```
- `keys` returns an Array with all the keys that a Hash knows
- `length` and `size` both tell how many key/value pairs the Hash has
- The new Hash syntax looks like this: ```{ one: "eins", two: "zwei", three: "drei" }```

# Objects, Classes, Methods

In Ruby everything is an object.

## Objects have classes

```ruby
$ irb
> "this is a string".class
=> String
> "this is a string".is_a?(String)
=> true
```

## Classes create objects

Objects are instances of classes, and inherit methods from their classes.

## Objects have methods

- Methods add behaviour that is useful to have for a particular type of object.
- Some methods, such as `class`, `is_a?`, are defined on all objects.

## Calling methods

Most methods in Ruby are questions, and return a relevant value. Calling them by using a dot.

## Passing arguments

```ruby
$ irb
> name = "Ruby Monstas"
> name.delete("by Mo")
=> "Runstas"
> name.prepend("Oh, hello, ")
=> "Oh, hello, Monstas"
```

## Listing methods

Can check Ruby documentation for each class's methods list: http://ruby-doc.org/core-2.2.0/
```ruby
# list and chain the methods call
$ irb
> "Ruby Monstas".methods.sort
=> [:*, :+, :<, :>, :[], :class, :downcase, :delete, :include?, :is_a?, :length, :prepend, :start_with?]
```

## Predicate methods

Methods that end with a question mark `?` will return either `true` or `false` by Ruby convention.

## Bang Methods

Bang methods end with an exlamation mark `!`, and often modify the object they are called on.

```ruby
name = "Ruby Monstas"
puts name.downcase!
puts name

##Output
#ruby monstas
#ruby monstas
```

# Writing Methods (Skipping some basic knowledge sections with methods)

Variables name things, methods name behaviour (code).

## Return values

- Every method always returns exactly one object in Ruby.
- If we don’t do anything else, then a method will return the return value of the last evaluated statement.

## Scopes

- **Scope** defines where a name (like a variable) is valid and accessible.
- A **method call creates a new scope** (or "room").
- Variables defined inside a method are **local to that method's scope**.
- Once the method ends, its **local variables are destroyed**.

- Ruby first looks for a **local variable** in the current scope.
   - If none exists, it looks for a **method**.
   - If neither exists, it raises an **error**.

- A method’s scope is like a **new room**.
   - Ruby brings objects (arguments) into the room and **labels them with names** (post-it notes).
   - Post-its in different rooms can have the **same name** but refer to **different objects**.

```ruby
number = 1

def add_to(number)
  number + 2
end

puts add_to(3)  # Outputs 5
```

## Printing things

- **`puts`** outputs a user-friendly version of an object.
- **`inspect`** returns a string representation of an object, showing how it was created in Ruby code.
- **`p`** is a shortcut for `puts object.inspect` — useful for debugging.

- **Use `puts`** for clean output in a program.
- **Use `p`** for debugging to see the raw internal structure of objects.

```ruby
$ irb
> something = [1, 2, 3]
> puts something
1
2
3

> puts [1, 2, 3].inspect
[1, 2, 3]
```

# Writing classes (Skip some known sections)

Objects have two key traits:
- They know stuff (store data).
- They can do stuff (perform actions with data).

## Defining classes

- A class is defined using the keyword **`class`**, a **name**, and the keyword **`end`**.
- **Class names** must start with an uppercase letter and should use **CamelCase**.
  - **Variable** and **method names** should use **snake_case**.
- The method **`new`** is defined on every class and returns a new instance of the class.

## Initializing objects

- The special method initialize is called under the hood when the object has been created by the class method new.

## Instance variables

- Instance variables live in, and are visible everywhere in the object’s scope:

```ruby
class Person
  def initialize(name)
    @name = name
  end
end
```

## Attribute readers

- An attribute reader returns the value of an instance variable.

```ruby
class Person
  def initialize
    @name = name
  end

  def name # Attribute reader - name
    @name
  end
end
```

## Attribute writers

- An attribute writer allows setting an instance variable.

```ruby
class Person
  def initialize
    # ...
  end

  def password=(password)
    @password = password
  end
end
```

## State and behaviour

State - instance variables + behaviour - methods.

## Object Scope and Self

- **Scope**: Ruby has two main scopes:
  - **Method’s local scope** – holds local variables.
  - **Object’s scope** – holds instance variables and methods.
  - When Ruby sees a name, it checks the local scope first, then the object’s scope.

- **self**: A special keyword that refers to the current object.
  - Use `self` to access the object’s methods when there’s a conflict with a local variable.

- **Keywords**: Special Ruby words like `class`, `def`, `end`, and `self` are not methods.

# Block

- A block is a piece of code that accepts arguments, and returns a value. A block is always passed to a method call:

```ruby
5.times do
  puts "Oh, hello from inside a block!"
end
```

## Alternative block syntaxes

- Blocks can be defined by enclosing code in `do` and `end`, or curly braces `{}`.
- Use curly braces `{}` for blocks when the code fits on one line.

```ruby
5.times { puts "hello!" }
```

## Block arguments

Block arguments are listed between pipes `|`, instead of parentheses.

```ruby
[1, 2, 3, 4, 5].each { |number| puts "#{number} was passed to the block" }
```

## Block return values

- Use the method `collect` to transform an array into another array + alias - `map`.
- Use the method `select` to create a new array with values that match criteria defined by the block.
- The method `detect` will pass each of the elements of the array to the block, one by one, and check the return value of the block.

```ruby
p [1, 2, 3, 4, 5].collect { |number| number + 1 } # [2, 3, 4, 5, 6]

p [1, 2, 3, 4, 5].select { |number| number.odd? } # [1, 3, 5]

p [1, 2, 3, 4, 5].detect { |number| number.even? } # 2 => like first function in Swift
```

## Inversion of control

- **Blocks enable inversion of control** – Methods pass control to the programmer using blocks.
- Instead of defining many specific methods (e.g., `select_odd`, `select_even`), Ruby provides a general method (`select`) and lets the programmer define the criteria using a block => allows greater flexibility and reduces the need for overly specific methods.

## Iterators

Iterators in Ruby are chainable:

```ruby
numbers = [1, 2, 3, 4, 5].map.with_index do |number, index|
  number + index
end
p numbers # [1, 3, 5, 7, 9]
```

# Conditionals

- **if statement** – Executes code if a condition is true.
- **elsif statement** – (Optional) Executes code if the previous if or elsif conditions are false and the elsif condition is true.
- **else statement** – (Optional) Executes code if none of the previous conditions are true.

Only one `if` and `else` statement is allowed per structure, but multiple `elsif` statements are allowed.

```ruby
if condition
  # code if condition is true
elsif another_condition
  # code if another_condition is true
else
  # code if none of the above conditions are true
end
```

## Nothingness and the truth

- **nil** – Represents "nothing" in Ruby. It’s a special object of class `NilClass`.
- **true** and **false** – Represent truth and falsehood in Ruby. They are objects of classes `TrueClass` and `FalseClass`.
- Everything in Ruby is truthy except `false` and `nil`, which are falsy. Even `0`, `""`, `[]`, and `{}` are truthy.

```ruby
if nil
  puts "This won't print"
else
  puts "nil is falsy"
end

if 0
  puts "0 is truthy"
end
```

# Operators (Skip a known section - Comparison operators)

## Arithmetical operators

- `+` – addition
- `-` – subtraction
- `*` – multiplication
- `/` – division
- `**` – exponentiation
- `%` – modulus (the rest of a division, e.g., `5 % 2` returns `1`)

## Logical operators

- Precedence:
  - `&&`, `||`, and `!` have higher precedence than `and`, `or`, and `not` (similar to multiplication binding stronger than addition).

## Operators are methods

- **Arithmetic Operators**: (`+`, `-`, `*`, `/`) are methods on numbers.
- **Dot Notation**: Ruby translates `2 + 3 * 4` into `2.+(3.*(4))`.
- **Syntax Sugar**: Ruby allows cleaner syntax (`2 + 3 * 4`) for readability, but it's essentially calling methods.
- **Other Operators**: Arrays and hashes also use operator methods:
  - `array[3] = 4` → `array.[]=(3, 4)`
  - `hash[:three] = 'drei'` → `hash.[]=(:three, 'drei')`
- **Useful for Custom Classes**: You can define similar behavior in your own classes.

# Bonus Chapters (Skip known sections)

## Top-level object

The top-level scope is an empty, anonymous object. All Ruby code starts in here.

```bash
$ irb
> is_a?(Object)
true
> methods
[:to_s, :inspect, ... ]
```

## Questions and commands

- **Question Methods** → Return information about an object.
  - `user.name` → Returns the user’s name.
  - `[1, 2, 3].size` → Returns the number of elements in the array.
  - `"a string".start_with?("a")` → Returns `true` if string starts with "a".
  - `[1, 2, 3].include?(1)` → Returns `true` if array includes `1`.

- **Command Methods** → Perform an action or modify an object.
  - `user.save` → Saves the user object to the database.
  - `array.sort!` → Sorts the array in place.
  - `puts` → Prints output to the screen (returns `nil`).

- **Non-Destructive Methods**
  - `array.sort` → Returns a new sorted array (non-destructive).

- **Destructive Methods**
  - `array.sort!` → Sorts the original array (destructive).

## Alternative Syntax

- Alternative string definition syntax using `%[any-character]The actual string[the same character]`: 
  -`%{A String}`, `%|A String|`, `%[A String]`
  - Lets you define strings without worrying about nested quotes.

```message = %(The given email address "#{address}" does not look like a valid email address.)```

- Alternative array syntax using %w:
  - `%w(Anne Elizabeth Erica)` creates an array of strings without needing quotes and commas.
  - `%w` is useful for defining word-based arrays quickly and cleanly.

```people = %w(Anne Elizabeth Erica)```

## Arguments and parentheses

In Ruby, when you define or call (execute, use) a method, you can omit the parentheses:
- Use parentheses for method calls with arguments, except for puts, p, require, and include.
- Omit parentheses for methods without arguments to keep code clean.

# Advanced Topics

## Using Libraries

- Use the digest library for hashing data:

```ruby
require 'digest'

class Person
  # ...

  def password=(password)
    @password = password
  end

  def encrypted_password
    Digest::SHA2.hexdigest(@password)
  end
end

def hash_password
  Digest::SHA2.hexdigest(@password)
end

person = Person.new("Ada")
person.password = "super secret"
puts person.hash_password # eabd522910ccdd77aef079feff0c7bb6486f6ab207ae6d3ed9e671208c92ab0f
```

## Modules

- Similar to classes but cannot be instantiated (no new method).
- Hold methods that can be shared across classes.

- Why use Module
  - **Reuse code**: Avoid duplication by defining shared methods in one place.
  - **Easy to update**: If you change the logic, you only need to update it in the module.
  - **Cleaner code**: Keeps clutter out of the class definition.

```ruby
require 'digest'

module Encryption
  def hash(string)
    Digest::SHA2.hexdigest(string)
  end
end

class Person
  include Encryption

  def password=(password)
    @password = password
  end

  def hash_password
    hash(@password)
  end
end
```

## Private methods

- **Instance variables are private**: Instance variables are only accessible from outside if exposed through attribute accessors.
- **Private methods**: Methods can be made private if they are not meant to be called from outside the object.
  - **Use `private` keyword**: Adding `private` before method definitions makes them callable only from within the object.

```ruby

module Encryption
  private

  def hash(string)
    Digest::SHA2.hexdigest(string)
  end
end

person = Person.new
p person.hash("super secret") # private method `hash' called for #<Person:0x007fa179863770 @name="Ada">
```

## Regular Expressions

[Rubular](http://rubular.com/): A helpful tool for testing regular expressions.

# Exercises

1. Working with Numbers - https://ruby-for-beginners.rubymonstas.org/exercises_2/numbers.html
```bash
minhpham@Mikes-MBP /#1 % ruby working-with-numbers.rb
8760
5256000
1040688000
=======================================================
1
1.5
1.5
8.0
1
=======================================================
1
1
1
3
4
0
1
=======================================================
false
false
true
true
true
```

2. Working with Strings - https://ruby-for-beginners.rubymonstas.org/exercises_2/strings.html
```bash
minhpham@Mikes-MBP #2 % ruby working-with-strings.rb
Ruby<3<3<3
=======================================================
10
=======================================================
1.23
```

3. Working with Arrays - https://ruby-for-beginners.rubymonstas.org/exercises_2/arrays_1.html
```bash
minhpham@Mikes-MBP \#3 % ruby working-with-arrays.rb
3
=======================================================
5
=======================================================
99
=======================================================
[2, 4, 6]
=======================================================
[6, 4, 2]
```

4. Working with Hashes - https://ruby-for-beginners.rubymonstas.org/exercises_2/hashes_1.html
```bash
minhpham@Mikes-MBP \#4 % ruby working-with-hashes.rb
dos
=======================================================
cuatro
=======================================================
Cuatro
=======================================================
true
true
true
false
=======================================================
{"uno" => :one, "dos" => :two, "tres" => :three}
```