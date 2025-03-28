# In the Array [1, 2, 3, 4, 5], what’s the index of the number 4?

p [1, 2, 3, 4, 5].index(4)

puts "======================================================="
# Create a new, empty file. Save it as arrays_1_1.rb. Fill in the following line:
# numbers = [1, 2, 3, 4, 5, 6]
# # your code goes here
# … so that, when you run your code (run ruby arrays_1-1.rb), you get the following output:
# 5

require File.expand_path('arrays_1_1.rb', __dir__)

run11

puts "======================================================="
# Copy your file to a new file: cp arrays_1-1.rb arrays_1-2.rb, then open this new file.
# Add another line before the line that you just added, so that, when you run your code, you get the following output:
# 99
require File.expand_path('arrays_1_2.rb', __dir__)

run12

puts "======================================================="
# Make a new file arrays_1-3.rb, and fill in the following line:
# numbers = [1, 2, 3, 4, 5, 6]
# # your code goes here
# p numbers
# … so that you get the following output:
# [2, 4, 6]

require File.expand_path('arrays_1_3.rb', __dir__)

run13

puts "======================================================="
# Again, copy your last file to a new file: cp arrays_1-3.rb arrays_1-4.rb, then open this new file.
# Now add another line after the one that you just added (i.e. before you finally output the array using p).
# Try to figure out how to transform your Array so you get the following output:
# [6, 4, 2]

require File.expand_path('arrays_1_4.rb', __dir__)

run14