# Below we have given you an array and a number. Write a program that checks to see if the number appears in the array.
# arr = [1, 3, 5, 7, 9, 11]
# number = 3

arr = [1, 3, 5, 7, 9, 11]
number = 3

puts arr.include?(number)

puts "======================================================="
# What will the following programs return? What is the value of arr after each?
# 1. arr = ["b", "a"]
#    arr = arr.product(Array(1..3))
#    arr.first.delete(arr.first.last)

# 2. arr = ["b", "a"]
#    arr = arr.product([Array(1..3)])
#    arr.first.delete(arr.first.last)

puts "1. [[\"b\"], [\"b\", 2], [\"b\", 3], [\"a\", 1], [\"a\", 2], [\"a\", 3]]"
puts "2. [[\"b\"], [\"a\", [1, 2, 3]]]"

puts "======================================================="
# How do you return the word "example" from the following array?
# arr = [["test", "hello", "world"],["example", "mem"]]

arr = [["test", "hello", "world"],["example", "mem"]]
puts arr.last.first

puts "======================================================="
# What does each method return in the following example?
# arr = [15, 7, 18, 5, 12, 8, 5, 1]
# 1. arr.index(5)
# 2. arr.index[5]
# 3. arr[5]

puts "With the following arr - `arr = [15, 7, 18, 5, 12, 8, 5, 1]`"
puts "1. arr.index(5) returns 3"
puts "2. arr.index[5] returns error - undefined method '[]'"
puts "2. arr[5] returns 8"

puts "======================================================="
# What is the value of a, b, and c in the following program?
# string = "Welcome to America!"
# a = string[6]
# b = string[11]
# c = string[19]

puts "a is 'e'"
puts "b is 'A'"
puts "c is nil"

puts "======================================================="
# You run the following code...
# names = ['bob', 'joe', 'susan', 'margaret']
# names['margaret'] = 'jody'

# ...and get the following error message:

# TypeError: no implicit conversion of String into Integer
#   from (irb):2:in `[]='
#   from (irb):2
#   from /Users/username/.rvm/rubies/ruby-2.5.3/bin/irb:12:in `<main>'

# What is the problem and how can it be fixed?

puts "Error reason: the code provides a string instead of an integer index to access an array element. The code is fixed and working as follow:"
names = ['bob', 'joe', 'susan', 'margaret']
names[3] = 'jody'
p names

puts "======================================================="
# Use the each_with_index method to iterate through an array of your creation that prints each index and value of the array.

test_arr = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]

test_arr.each_with_index do |value, index|
  puts "Index: #{index}, Value: #{value}"
end

puts "======================================================="
# Write a program that iterates over an array and builds a new array that is the result of incrementing each value in the original array by a value of 2.
# You should have two arrays at the end of this program, The original array and the new array you've created. Print both arrays to the screen using the p method instead of puts.

original_arr = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12]
new_arr = original_arr.map { |value| value + 2 }

p original_arr
p new_arr
