# dictionary = { :one => 'uno', :two => 'dos', :three => 'tres' }
# # your code goes here
# … so that it prints out dos.
require File.expand_path('hash_1-1.rb', __dir__)

run11

puts "======================================================="
# Make a new file hashes_1-2.rb, and fill in the following line:
# dictionary = { :one => 'uno', :two => 'dos', :three => 'tres' }
# # your code goes here
# puts dictionary[:four]
# … so that it prints out cuatro.

require File.expand_path('hash_1-2.rb', __dir__)

run12

puts "======================================================="
# Copy that file to a new file cp hashes_1-2.rb hashes_1-3.rb, and change your code so that it prints out the following.
# Cuatro

require File.expand_path('hash_1-3.rb', __dir__)

run13

puts "======================================================="
# There is a method on hashes that allows to check if a certain key is defined on the hash.
# Try creating a hash like the one above, calling the method and passing keys like :one, :two, :four, and :ten.

dictionary = { :one => 'uno', :two => 'dos', :three => 'tres', :four => 'cuatro' }

p dictionary.has_key?(:one)
p dictionary.has_key?(:two)
p dictionary.has_key?(:four)
p dictionary.has_key?(:ten)

puts "======================================================="
# There is a method on hashes that flips keys and values.
# Make a new file hashes_1-5.rb, and fill in the following line using that method:
# dictionary = { :one => 'uno', :two => 'dos', :three => 'tres' }
# # your code goes here
# This should then output:
# { 'uno' => :one, 'dos' => :two, 'tres' => :three }

require File.expand_path('hash_1-5.rb', __dir__)

run15