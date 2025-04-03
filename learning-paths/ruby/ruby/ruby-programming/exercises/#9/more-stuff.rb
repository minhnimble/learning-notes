# Write a program that checks if the sequence of characters "lab" exists in the following strings. If it does exist, print out the word.
# "laboratory"
# "experiment"
# "Pans Labyrinth"
# "elaborate"
# "polar bear"

string_arr = ["laboratory", "experiment", "Pans Labyrinth", "elaborate", "polar bear"]
string_arr.each do |string|
  if string.include?("lab")
    puts string
  end
end

puts "======================================================="
# What will the following program print to the screen? What will it return?
# def execute(&block)
#   block
# end
# execute { puts "Hello from inside the execute method!" }

puts "The program will return a Proc object and puts nothing. Need to activate the Proc object with the `.call` method to print out the provided message."

puts "======================================================="
# What is exception handling and what problem does it solve?

puts "Exception handling is a structure used to handle the possibility of an error occurring in a program."
puts "It is a way of handling the error by changing the flow of control without exiting the program entirely."

puts "======================================================="
# Modify the code in exercise 2 to make the block execute properly.

def execute(&block)
  block.call
end
execute { puts "Hello from inside the execute method!" }

puts "======================================================="
# Why does the following code...
# def execute(block)
#   block.call
# end
# execute { puts "Hello from inside the execute method!" }

# Give us the following error when we run it?

# block.rb1:in `execute': wrong number of arguments (0 for 1) (ArgumentError)
# from test.rb:5:in `<main>'

puts "The `block` param misses the ampersand sign `&` that allows a block to be passed as a parameter."
