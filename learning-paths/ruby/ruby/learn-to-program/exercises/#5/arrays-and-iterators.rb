# Write the program we talked about at the very beginning of this chapter - a program which asks us to type in as many words as we want (one word per line, continuing until we just press Enter on an empty line), and which then repeats the words back to us in alphabetical order.
# Hint: There's a lovely array method which will give you a sorted version of an array: sort. Use it!

words = []
puts "Enter as many words as you want (one word per line, continuing until pressing Enter on an empty line):"
word = gets.chomp

while word != ""
  words << word
  word = gets.chomp
end

puts "Here are the sorted words you entered (using sort func):"
puts words.sort

puts "==================================================="
# Try writing the above program without using the sort method. A large part of programming is solving problems, so get all the practice you can!

words = []
puts "Enter as many words as you want (one word per line, continuing until pressing Enter on an empty line):"
word = gets.chomp

while word != ""
  if words.empty?
    words << word
  else
    words.each do |w|
      if word < w
        words.insert(words.index(w), word)
        break
      elsif w == words.last
        words << word
        break
      end
    end
  end
  word = gets.chomp
end

puts "Here are the sorted words you entered (without using sort func):"
puts words

puts "==================================================="
# Rewrite your Table of Contents program (from the chapter on methods). Start the program with an array holding all of the information for your Table of Contents (chapter names, page numbers, etc.). Then print out the information from the array in a beautifully formatted Table of Contents.

table_of_contents = [
  ["Chapter 1: Getting Started", "page 1"],
  ["Chapter 2: Numbers", "page 9"],
  ["Chapter 3: Letters", "page 13"]
]

puts "Table of Contents".center(50)
puts ""
table_of_contents.each do |chapter|
  puts chapter[0].ljust(30) + chapter[1].rjust(20)
end
