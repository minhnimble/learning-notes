# Write an Angry Boss program. It should rudely ask what you want. Whatever you answer, the Angry Boss should yell it back to you, and then fire you. For example, if you type in I want a raise., it should yell back WHADDAYA MEAN "I WANT A RAISE."?!?  YOU'RE FIRED!!

puts "What do you want?"
answer = gets.chomp
puts "WHADDAYA MEAN \"#{answer.upcase}\"?!? YOU'RE FIRED!!"

puts "==================================================="
# So here's something for you to do in order to play around more with center, ljust, and rjust: Write a program which will display a Table of Contents so that it looks like this:
# Table of Contents
#
# Chapter 1:  Numbers                        page 1
# Chapter 2:  Letters                       page 72
# Chapter 3:  Variables                    page 118

puts "Table of Contents".center(50)
puts ""
puts "Chapter 1:  Numbers".ljust(30) + "page 1".rjust(20)
puts "Chapter 2:  Letters".ljust(30) + "page 72".rjust(20)
puts "Chapter 3:  Variables".ljust(30) + "page 118".rjust(20)
