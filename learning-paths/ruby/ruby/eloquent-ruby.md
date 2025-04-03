# Basics

The Document class:

```ruby
class Document
  attr_accessor :title, :author, :content
  def initialize(title, author, content)
    @title = title
    @author = author
    @content = content
  end
  def words
    @content.split
  end
  def word_count
    words.size
  end
end
```

Note that the rule is to use two spaces per indent: The Ruby convention is to never use tabs to indent. Ever.

## Comments

### Simple Comment Syntax
- Use `#` for single-line comments.
- Ruby also supports multiline comments with `=begin` and `=end`, but `#` is preferred.

### When and How Much to Comment
- Good Ruby code should be self-explanatory; avoid unnecessary comments.
- Don’t add boilerplate comments just for the sake of it.

### Good Reasons to Comment
- Focus comments on **how to use** the code, not why or how it was written.
- Provide examples to clarify usage.

### Types of Useful Comments
- **How-to-use comments** – Explain how to use a method or class.
- **Background comments** – Include author info, copyright, and purpose.
- **How-it-works comments** – Explain complex algorithms separately from usage instructions.
- **Inline comments** – Use sparingly to clarify tricky code, not to state the obvious.

### Avoid Bad Comments
- Don’t repeat what the code already says.
- Don’t use comments to patch over bad code — refactor instead.
- Code should be clear enough to speak for itself.

### Good Code Needs No Explanation

- Well-named classes, methods, and variables reduce the need for comments.
- Clean, readable code minimizes the need for additional guidance.

## Camels for Classes, Snakes Everywhere Else

```ruby
def count_words_in( the_string )
  the_words = the_string.split
  the_words.size
end
```

## Parentheses Are Optional but Are Occasionally Forbidden

Tries hard not to require any syntax it can do without - When you define or call a method, you are free to add or omit the parentheses around the arguments.

## Folding Up Those Lines

- Use sparingly to maintain readability.
- Clear and readable code is more important than concise code.
- Avoid cramming statements together just because it's possible.

## Folding Up Those Code Blocks

- Braces {} → Single statement on one line.
- do/end → Multiple statements over several lines.
- The two forms are functionally identical — the choice is purely for readability.

## In the wild

– Read Ruby code from the standard library (e.g., set.rb).
- Methods answering a yes/no question end with ? (e.g., include?, empty?).
- Methods that modify an object in place end with ! (e.g., flatten!, map!).
- The Float method starts with an uppercase letter (unusual in Ruby).
- Float converts a string to a floating-point number (e.g., pi = Float('3.14159')). 

## If, Unless, While, and Until

Ruby’s `if` statement works like in most languages. For example, to allow changes only when a document is writable, you can use a basic `if` statement:

```ruby
if @writable
  @title = new_title
end
```

Instead of `if not`, use `unless` for better readability:

```ruby
@title = new_title unless @read_only
```

`unless` reduces the statement’s length and makes it easier to read. `while` has a counterpart `until`, which runs `until` the condition becomes `true`:

```ruby
until document.printed?
  document.print_next_page
end
```

## Use the Modifier Forms Where Appropriate

Use `modifier forms` when the body is a single statement to make code cleaner and more readable:

```ruby
@title = new_title unless @read_only
document.print_next_page while document.pages_available?
document.print_next_page until document.printed?
```

## Use each, Not for

Ruby has a familiar `for` loop for iterating through arrays. Both approaches are equivalent because Ruby internally implements `for` using `each`. Therefore, it's better to use `each` directly for simplicity and clarity.

```ruby
# for
fonts = ['courier', 'times roman', 'helvetica']
for font in fonts
  puts font
end

# each
fonts.each do |font|
  puts font
end
```

## A Case of Programming Logic (switch)

```ruby
author = case title
         when 'War And Peace' then 'Tolstoy'
         when 'Romeo And Juliet' then  'Shakespeare'
         else "Don't know"
         end
```

## Problems to Avoid

- **Iterating with `each` and `map`** is powerful but can cause issues if the collection is modified during iteration.
    - **Example:** Removing elements from an array while using `each` can mess up indexing and skip elements.

- **Thread safety** – If multiple threads modify a collection during iteration, it can cause unpredictable results.

- **Array expansion** – Adding an element far beyond the array’s size creates many `nil` values to fill the gap.

- **Misuse of arrays and hashes** – Arrays allow duplicates and require searching for uniqueness, while hashes are meant for key-value pairs.

- **Use a `Set`** – For fast lookup and uniqueness, use Ruby’s `Set` class instead of arrays or hashes.
    - **Example:** `word_set = Set.new(words)` ensures no duplicates and quick membership checks.

## Coming Up with a String

- **Single-quoted strings** are more literal and only escape backslashes and quotes.
- **Double-quoted strings** allow interpolation (`#{}`) and special characters (e.g., `\n`, `\t`).
- To avoid backslash confusion, use different types of quotes or the `%q` and `%Q` syntax.
  - `%q` creates single-quoted style strings; `%Q` creates double-quoted style strings.
- **Strings can span multiple lines**; newlines can be avoided using a trailing backslash (`\`).
- **Here documents** (`<<`) are useful for long multi-line strings.

## Another API to Master (Other String APIs)

### Whitespace Trimming
- `lstrip` – Removes leading whitespace.
- `rstrip` – Removes trailing whitespace.
- `strip` – Removes whitespace from both ends.

### Chopping vs. Chomping
- `chomp` – Removes one newline at the end.
- `chop` – Removes the last character, regardless of what it is.

### Case Manipulation
- `upcase`, `downcase`, `swapcase` – Modify letter cases.

### Substitution
- `sub` – Replaces the first match.
- `gsub` – Replaces all matches.

### Splitting
- `split` – Breaks a string into an array using whitespace or a specified delimiter.

### Destructive Methods
- Methods ending in `!` modify the string in place (e.g., `sub!`, `gsub!`).

### Indexing
- `index` – Finds the starting position of a substring.

### Iteration
- `each_char` – Iterates over characters.
- `each_byte` – Iterates over bytes.
- `each_line` – Iterates over lines.

### Collections Behavior
- Ruby strings act as collections but omit the `each` method due to their mixed nature of characters and bytes.

## In the wild (Public practices)

- **The `html_escape` method** from the RSS library sanitizes strings for HTML/XML using `gsub` and regular expressions.
- **Rails uses string processing** for inflection (e.g., converting `current_employee.rb` to `CurrentEmployee`).
- **Inflection rules in Rails** are defined as pattern-replacement pairs (e.g., `'person'` → `'people'`).
- **Rails applies inflection rules** using `gsub!` to modify strings in place.

## Staying Out of Trouble (Problems to Avoid)

- **Ruby strings are mutable** – Modifying a string affects all references to it.
- **Mutability example** – Changing `first_name[0] = 'D'` also changes `given_name`.
- **Best practice** – Use `first_name = first_name.upcase` instead of `first_name.upcase!` to avoid unintended side effects.
- **Flexible indexing** – Use negative indices to count from the end (e.g., `-1` for the last character).
- **Range-based indexing** – You can extract substrings using ranges (e.g., `"abcde"[3..4]` → `"de"`).

## Matching One Character at a Time

### Basic Matching
- Regular expressions match letters and numbers directly (e.g., `x` matches `"x"`, `123` matches `"123"`).
- Case matters in regex (e.g., `R2D2` ≠ `r2d2`).

### Special Characters
- `.` matches any single character.
- `..` matches any two characters.
- Use a backslash (`\`) to escape special characters (e.g., `\.`, `Mr\. Olsen`).

### Combining Patterns
- `A.` matches any two-character string starting with `A`.
- `...X` matches any four-character string ending in `X`.
- `.r\.Smith` matches both `"Dr. Smith"` and `"Mr. Smith"`, but not `"Mrs. Smith"`.

### Controlled Matching
- Regular expressions can be tailored to match specific patterns like only letters, vowels, or numbers.

## Sets, Ranges, and Alternatives

### Sets

**Sets** match any one of a group of characters using square brackets (e.g., `[aeiou]` matches any single lowercase vowel).
**Examples:**
- `[0123456789]` → Matches any single digit.
- `[0123456789abcdef]` → Matches any single hexadecimal digit.
- `[Rr]uss [Oo]lsen` → Matches "Russ Olsen" with or without capital letters.

### Ranges

Use `-` to define a sequence of characters:
- `[0-9]` → Matches any decimal digit.
- `[a-z]` → Matches any lowercase letter.
- `[0-9a-zA-Z_]` → Matches any letter, digit, or underscore.

### Shortcuts for Common Sets

- `\d` → Matches any digit.
- `\w` → Matches any letter, digit, or underscore.
- `\s` → Matches any whitespace character (space, tab, newline).

### Alternatives

Use `|` to create alternatives:
- `A|B` → Matches either A or B.
- `AM|PM` → Matches either "AM" or "PM".
- `(car|boat)` → Matches "The car is red" or "The boat is red".
Example: `\d\d:\d\d (AM|PM)` → Matches a time format like `"12:34 AM"`.

## The Regular Expression Star

### Asterisk (`*`)

- **Matches zero or more of the preceding element.**:
  - `A*` → Matches zero or more A’s (includes an empty string).
  - `AB*` → Matches A followed by zero or more B’s (`A`, `AB`, `ABB`, `ABBBB`).
  - `R*uby` → Matches `uby`, `Ruby`, `RRuby`, `RRRRRuby`, etc.
  - `Rub*y` → Matches `Ruy`, `Ruby`, `Rubbbby`, etc.

- **Positioning:**:
  - Asterisk can appear at the beginning, middle, or end of the pattern.
  - Multiple asterisks can be used in the same pattern.

### Asterisk (`*`) with Groups:

- `R*u*by` → Matches any number of R’s followed by any number of u’s, followed by "by."

### Asterisk with Sets:

- `[aeiou]*` → Matches any number of vowels.
- `[0-9]*` → Matches any number of digits.
- `[0-9a-f]*` → Matches any number of hexadecimal digits.

### Dot + Asterisk (`.*`)

- **Matches any number of any characters** (essentially "anything"):
  - `George.*` → Matches "George" followed by anything.
  - `.*George` → Matches anything followed by "George."
  - `.*George.*` → Matches anything containing "George."

## Regular Expressions in Ruby

### Regexp Type and Syntax

Ruby has a built-in `Regexp` data type with its own literal syntax (`/pattern/`).

**Example:** `/\d\d:\d\d (AM|PM)/`

### Matching with `=~` Operator

The `=~` operator returns the starting index of the match or `nil` if no match is found.

**Example:** `/PM/ =~ '10:24 PM'` → returns `6` (index of match).

If no match: `/May/ =~ 'Sometime in June'` → returns `nil`.

### Use as a Boolean

`=~` returns a number (truthy) or `nil` (falsey) and can be used in conditionals.

**Example:** `puts "It's morning!" if /AM/ =~ the_time`

### Ambidextrous `=~`

Works with the string or the regular expression first.

**Example:** `'10:24 AM' =~ /AM/` → same as `/AM/ =~ '10:24 AM'`

### Case Sensitivity

Regular expressions are case sensitive by default. Add `i` at the end to make it case-insensitive (`/AM/i`).

**Example:** `/AM/i =~ 'am'` → returns a match.

### Using Regex with String Methods

`gsub` can use regex for replacements.

**Example:** `@content.gsub!( /\d\d:\d\d (AM|PM)/, '**:** **' )` → Replaces times like `"10:24 PM"` with `**:** **`

## Beginnings and Endings

### Matching Start and End of Strings

- `\A` → Matches the beginning of a string.
  **Example:** `/\AOnce upon a time/` → Matches only if the string starts with "Once upon a time."
- `\z` → Matches the end of a string.
  **Example:** `/and they all lived happily ever after\z/` → Matches only if the string ends with that phrase.

### Multiline Matching

- `^` → Matches the beginning of a string or the beginning of any line in a multiline string.
  **Example:** `/^Once upon a time/` → Matches "Once upon a time" at the beginning of a line in a multiline string.
- `$` → Matches the end of a string or the end of any line in a multiline string.
  **Example:** `/happily ever after\.$/` → Matches "happily ever after." at the end of a line.

### Matching Across Multiple Lines

- `.` → By default, matches any character **except** the newline (`\n`).
- Adding `m` → Allows `.` to match across multiple lines.
  **Example:** `/^Once upon a time.*happily ever after\.$/m` → Matches text spanning multiple lines from "Once upon a time" to "happily ever after."

## The Two Faces of Strings

### Symbols vs Strings
- Symbols (`:dog`) are similar to strings (`"dog"`) as both represent a sequence of characters.

### Interchangeability
Symbols and strings are often interchangeable in Ruby code.

**Example:**
```ruby
book = Book.find(:all) # Using a symbol
book = Book.find('all') # Using a string
```

### Why Use Symbols?
- Symbols are used instead of strings because they are more lightweight and efficient (though the difference may seem small at first).

### Simplified Explanation
- Symbols are essentially simplified strings, but with some internal differences that make them useful for flags, keys, and identifiers.

## Not Quite a String

- In Ruby, strings can also be used as symbols or flags to represent specific commands or states (e.g., :all to mean "all records").
- Symbols are primarily for identification and comparison rather than modification. Symbols like :all are more readable and meaningful than numeric or hex codes.

## Optimized to Stand for Something

### Uniqueness of Symbols
- There can only be **one instance** of a given symbol.
- If `a = :all` and `c = :all`, `a` and `c` are guaranteed to refer to the same object.
- Comparison methods (`==`, `===`, `.eql?`, `.equal?`) all return `true` for identical symbols.

### Strings Create New Objects
- `"all"` creates a **new string** every time it's used, even if the content is identical.
- Therefore, two `"all"` strings are equal in value but **not the same object**.

### Symbols are Immutable
- Once created, a symbol **cannot be changed** (e.g., you can’t uppercase `:all`).
- This makes symbols reliable for representing **fixed values**.

### Symbols as Hash Keys
- Symbols are ideal hash keys because:
  - **Comparison is fast** since symbols are unique.
  - Symbols **can't change**, so they prevent key modification issues.
- **String keys** require special handling in `Hash` to avoid issues when mutated.

### Converting Between Symbols and Strings

```ruby
# Convert a symbol to a string using to_s:
the_string = :all.to_s

# Convert a string to a symbol using to_sym:
the_symbol = 'all'.to_sym
```

## Common String vs. Symbol Mistake and Solution

- Mixing symbols and strings as hash keys leads to bugs

```ruby
person[:eyes] = 'misty blue'
puts "Eyes: #{person['eyes']}" # Wrong (uses string key instead of symbol)
puts "Eyes: #{person[:eyes]}" # Correct
```

- Solution: Rails provides `HashWithIndifferentAccess`, which allows mixing of string and symbol keys without issue.

## A Quick Review of Classes, Instances, and Methods

Quote: Treat everything like an object in Ruby because everything is.

### Classes as Containers for Methods

- Classes define methods that can be called on instances.

```ruby
class Document
  def words
    @content.split
  end

  def word_count
    words.size
  end
end
```

### Classes as Factories
- Classes create instances using `new`.

```ruby
doc = Document.new('Ethics', 'Spinoza', 'By that which is...')
doc.word_count
```

### The `self` Keyword
- `self` refers to the instance on which the method was called.

```ruby
def about_me
  puts "My title is #{self.title}"
end
```

- When calling a method on `self`, you can omit `self` unless necessary.

### Inheritance and Superclasses
- Every class (except one) has a superclass.
- If a method isn’t found in the class, Ruby looks for it in the superclass.

```ruby
class RomanceNovel < Document
  # Inherits from Document
end
```

## Objects All the Way Down

- **Consistency in Object-Oriented Philosophy**: Ruby treats everything consistently as an object.
- **Method Calls on Objects**: `-3.abs` works because `-3` is an object and `abs` is a method on that object.
- **Everything is an Object**: Strings, symbols, regular expressions, and even `true` and `false` are objects with their own methods.
- **Classes are Objects**: `true.class.class` returns `Class`, showing that even classes are objects.
- **Nil is an Object**: `nil` is an instance of `NilClass` and can respond to methods like `nil?`.
- **If You Can Reference It, It’s an Object**: Anything that can be assigned to a variable is treated as an object in Ruby.

> [!NOTE] Stop Reading, Start Practicing!
> Reading is useful, but true learning happens through practice. Instead of just absorbing information, take action:
>
> - ✅ Solve an exercise related to the topic
> - ✅ Build a small project
> - ✅ Experiment and debug real code
>
> **Remember:** *"Knowing is not enough; we must apply. Willing is not enough; we must do."* — Goethe
>
> **Pause here and start coding!** 🚀

