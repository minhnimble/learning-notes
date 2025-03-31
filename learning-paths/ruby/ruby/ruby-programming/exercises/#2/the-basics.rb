# Add two strings together that, when concatenated, return your first and last name as your full name in one string.
# For example, if your name is John Doe, think about how you can put "John" and "Doe" together to get "John Doe".

first_name = "John"
last_name = "Doe"

puts "#{first_name} #{last_name}"

puts "======================================================="
# Use the modulo operator, division, or a combination of both to take a 4 digit number and find the digit in the: 1) thousands place 2) hundreds place 3) tens place 4) ones place

number = 4321

puts number / 1000 # thousands place

puts number / 100 % 10 # hundreds place

puts number / 10 % 10 # tens place

puts number % 10 # ones place

puts "======================================================="
# Write a program that uses a hash to store a list of movie titles with the year they came out. Then use the puts command to make your program print out the year of each movie to the screen.
# The output for your program should look something like this.
# 1975
# 2004
# 2013
# 2001
# 1981

movies_dict = { "Movie 1" => 1975, "Movie 2" => 2004, "Movie 3" => 2013, "Movie 4" => 2001, "Movie 5" => 1981 }
movies_dict.each { |_ , year| puts year }

puts "======================================================="
# Use the dates from the previous example and store them in an array. Then make your program output the same thing as exercise 3.

dates = [1975, 2004, 2013, 2001, 1981]
dates.each { |year| puts year }

puts "======================================================="
# Write a program that outputs the factorial of the numbers 5, 6, 7, and 8.

puts 5*4*3*2 #5
puts 6*5*4*3*2 #6
puts 7*6*5*4*3*2 #7
puts 8*7*6*5*4*3*2 #8

puts "======================================================="
# Write a program that calculates the squares of 3 float numbers of your choosing and outputs the result to the screen.

puts 3.14*3.14
puts 5.67*5.67
puts 10.13*10.13

puts "======================================================="
# What does the following error message tell you?
# SyntaxError: (irb):2: syntax error, unexpected ')', expecting '}'
#  from /usr/local/rvm/rubies/ruby-2.5.3/bin/irb:16:in `<main>'

puts "The error is because we are providing a ) wrongly in a place where it needs a }, for example this following code will trigger the error:"
puts"test_dict = \"Test 1\" => 1, \"Test 2\" => 2 )"
