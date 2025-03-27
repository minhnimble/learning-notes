# "99 bottles of beer on the wall..." Write a program which prints out the lyrics to that beloved classic, that field-trip favorite: "99 Bottles of Beer on the Wall."
def bottles_of_beer(n)
  if n <= 0
    puts "No more bottles of beer on the wall, no more bottles of beer."
    puts "We've taken them down and passed them around; now we're drunk and passed out!"
  else
    puts "#{n} bottles of beer on the wall, #{n} bottles of beer."
    puts "Take one down and pass it around, #{n-1} bottles of beer on the wall."
  end
end

bottles_of_beer(99)
bottles_of_beer(98)

puts "==================================================="
# Write a Deaf Grandma program. Whatever you say to grandma (whatever you type in), she should respond with HUH?!  SPEAK UP, SONNY!, unless you shout it (type in all capitals). If you shout, she can hear you (or at least she thinks so) and yells back, NO, NOT SINCE 1938! To make your program really believable, have grandma shout a different year each time; maybe any year at random between 1930 and 1950. (This part is optional, and would be much easier if you read the section on Ruby's random number generator at the end of the methods chapter.) You can't stop talking to grandma until you shout BYE.
# Hint: Don't forget about chomp! 'BYE' with an Enter is not the same as 'BYE' without one!
# Hint 2: Try to think about what parts of your program should happen over and over again. All of those should be in your while loop.

puts "What do you want to say to grandma?"
input = gets.chomp

while input != "BYE"
  if input == input.upcase
    puts "NO, NOT SINCE #{rand(1930..1950)}!"
  else
    puts "HUH?! SPEAK UP, SONNY!"
  end
  input = gets.chomp
end

puts "==================================================="
# Extend your Deaf Grandma program: What if grandma doesn't want you to leave? When you shout BYE, she could pretend not to hear you. Change your previous program so that you have to shout BYE three times in a row. Make sure to test your program: if you shout BYE three times, but not in a row, you should still be talking to grandma.

puts "What do you want to say to grandma?"
input = gets.chomp
count = 0
while count < 2
  if input == "BYE"
    count += 1
  else
    count = 0
  end

  if input == input.upcase
    puts "NO, NOT SINCE #{rand(1930..1950)}!"
  else
    puts "HUH?! SPEAK UP, SONNY!"
  end
  input = gets.chomp
end

puts "==================================================="
# Leap Years. Write a program which will ask for a starting year and an ending year, and then puts all of the leap years between them (and including them, if they are also leap years). Leap years are years divisible by four (like 1984 and 2004). However, years divisible by 100 are not leap years (such as 1800 and 1900) unless they are divisible by 400 (like 1600 and 2000, which were in fact leap years). (Yes, it's all pretty confusing, but not as confusing as having July in the middle of the winter, which is what would eventually happen.)

puts "What is the starting year?"
start_year = gets.chomp.to_i
puts "What is the ending year?"
end_year = gets.chomp.to_i

for year in start_year..end_year
  if year % 4 == 0 && year % 100 != 0 || year % 400 == 0
    puts year
  end
end
