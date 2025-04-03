# What does the `each`` method in the following program return after it is finished executing?

# x = [1, 2, 3, 4, 5]
# x.each do |a|
#   a + 1
# end

puts "It only increases each number in the x array to 1 but no assignment, thus it will print the x array as the same in the end - `[1, 2, 3, 4, 5]`."

puts "======================================================="
# Write a while loop that takes input from the user, performs an action, and only stops when the user types "STOP". Each loop can get info from the user.

value = ""

while value != "STOP" do
  puts "Type something:"
  value = gets.chomp
  if value != "STOP"
    puts "Perform #{value} action!"
  end
end

puts "======================================================="
# Write a method that counts down to zero using recursion.


def recursive_count_down_to_zero count
  if count >= 0
    puts count
    recursive_count_down_to_zero(count - 1)
  end
end

puts "Starting the count down..."

recursive_count_down_to_zero(40)

puts "Countdown completed!"