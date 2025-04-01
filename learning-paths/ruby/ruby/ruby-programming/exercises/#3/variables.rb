# Write a program called name.rb that asks the user to type in their name and then prints out a greeting message with their name included.
require File.expand_path('name.rb', __dir__)

name

puts "======================================================="
# Write a program called age.rb that asks a user how old they are and then tells them how old they will be in 10, 20, 30 and 40 years. Below is the output for someone 20 years old.
# output of age.rb for someone 20 yrs old
# How old are you?
# In 10 years you will be:
# 30
# In 20 years you will be:
# 40
# In 30 years you will be:
# 50
# In 40 years you will be:
# 60
require File.expand_path('age.rb', __dir__)

age

puts "======================================================="
# Add another section onto name.rb that prints the name of the user 10 times. You must do this without explicitly writing the puts method 10 times in a row. Hint: you can use the times method to do something repeatedly.

print_name_10_times

puts "======================================================="
# Modify name.rb again so that it first asks the user for their first name, saves it into a variable, and then does the same for the last name. Then outputs their full name all at once.

full_name

puts "======================================================="
# Look at the following programs...
# ================================
# x = 0
# 3.times do
#   x += 1
# end
# puts x
# ================================
# and...
# ================================
# y = 0
# 3.times do
#   y += 1
#   x = y
# end
# puts x
# ================================
# What does x print to the screen in each case? Do they both give errors? Are the errors different? Why?
puts "The 1st case - x will print '3'"
puts "The 2nd case - x will also print '3'"
puts "No error for both cases, because:"
puts "For the 1st case, += will modify the x value directly and after the last time run for the times block, the x value will equal 3"
puts "For the 2nd case, x will be updated with the new y value for each time run in the times block, and the last x assignment will be to y which equals to 3"