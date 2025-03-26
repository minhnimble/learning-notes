## `Yield` Keyword:
- `yield` allows passing additional instructions during a method invocation.
- It customizes the method based on the block provided.

## Blocks:
- A block is part of Ruby's method syntax.
- When a block is passed, it replaces the `yield` keyword in the method definition.

## Handling Missing Blocks:
- If `yield` is called without a block, `LocalJumpError` is raised.
- Use `Kernel#block_given?` to make the block optional.

## Yield with Arguments:
- `yield` can pass arguments to the block using `|args|`.
- The block receives and processes these arguments.

```ruby
def yield_with_arguments
  hello = 'Hello'
  world = 'World!'

  yield(hello, world)
end

yield_with_arguments { |hello, world| puts "#{hello} #{world}" } # => Hello World!
```

## Return Value:
- The return value of a block can be captured by assigning the result of `yield` to a variable.

```ruby
def yield_with_return_value
  hello_world = yield

  puts hello_world
end

yield_with_return_value { "Hello World!" } # => Hello World!
```

## Enumerable#map Example:
- `array.map { |n| n + 2 }` creates a new array with modified elements.
- Original array remains unchanged.

## Custom `my_map` Method:
1. Create a temporary array to store results.
2. Use `self.each` to iterate over the array.
3. Call `yield(elem)` and store the result in the temporary array.
4. Return the temporary array.
5. Handle missing blocks using `block_given?` to return a copy of the original array.

```ruby
class Array
  def my_map
    return self.dup unless block_given?
    ary = []
    self.each do |elem|
      ary << yield(elem)
    end
    ary
  end
end

$> array = [1, 2, 3]
 => [1, 2, 3]
$> array.my_map {|n| n + 2}
 => [3, 4, 5]
$> array.my_map
 => [1, 2, 3]
```
