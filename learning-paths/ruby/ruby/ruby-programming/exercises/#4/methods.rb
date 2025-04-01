# Write a program that prints a greeting message. This program should contain a method called greeting that takes a name as its parameter and returns a string.

def greeting name
  puts "Hi #{name}!"
end

greeting("Mike")

puts "======================================================="
# What do the following expressions evaluate to? That is, what value does each expression return?
# 1. x = 2
# 2. puts x = 2
# 3. p name = "Joe"
# 4. four = "four"
# 5. print something = "nothing"
puts "1. it will print 2"
puts "2. it will print nil"
puts "3. it will print 'Joe'"
puts "4. it will print 'four'"
puts "4. it will print nil"

puts "======================================================="
# Write a program that includes a method called multiply that takes two arguments and returns the product of the two numbers.

def multiply(a, b)
  puts a * b
end

multiply(10, 5)

puts "======================================================="
# What will the following code print to the screen?
# def scream(words)
#   words = words + "!!!!"
#   return
#   puts words
# end
# scream("Yippeee")

puts "It doesn't print anything since the 'return' call happens before the 'puts words' call to print out something."

puts "======================================================="
# 1) Edit the method definition in exercise #4 so that it does print words on the screen. 2) What does it return now?
def scream(words)
  words = words + "!!!!"
  puts words
end

puts "Now when calling 'scream(\"Yippeee\")', it will print the following message:"
scream("Yippeee")

puts "======================================================="
# What does the following error message tell you?
# ArgumentError: wrong number of arguments (1 for 2)
#   from (irb):1:in `calculate_product'
#   from (irb):4
#   from /Users/username/.rvm/rubies/ruby-2.5.3/bin/irb:12:in `<main>'

puts "When calling a method called `calculate_product` that requires `two` arguments, but we are only providing `one``."