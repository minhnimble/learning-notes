# Use the each method of Array to iterate over [1, 2, 3, 4, 5, 6, 7, 8, 9, 10], and print out each value.

arr = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
arr.each do |value|
  puts value
end

puts "======================================================="
# Same as above, but only print out values greater than 5.

arr.each do |value|
  if value > 5
    puts value
  end
end

puts "======================================================="
# Now, using the same array from #2, use the select method to extract all odd numbers into a new array.

odd_arr = arr.filter { |value| value.odd? }
p odd_arr

puts "======================================================="
# Append 11 to the end of the original array. Prepend 0 to the beginning.

arr << 11
arr.prepend(0)
p arr

puts "======================================================="
# Get rid of 11. And append a 3.

arr.delete(11)
arr << 3
p arr

puts "======================================================="
# Get rid of duplicates without specifically removing any one value.

arr.uniq!
p arr

puts "======================================================="
# What's the major difference between an Array and a Hash?

puts "Array has only values, Hash has a pair of keys and values."

puts "======================================================="
# Create a Hash, with one key-value pair, using both Ruby syntax styles.

old_hash = {:foo => 0, :bar => 1, :baz => 2}
new_hash = {foo: 0, bar: 1, baz: 2}
p old_hash
p new_hash

puts "======================================================="
# Suppose you have a hash h = {a:1, b:2, c:3, d:4}
# 1. Get the value of key `:b`.
# 2. Add to this hash the key:value pair `{e:5}`
# 3. Remove all key:value pairs whose value is less than 3.5

h = {a:1, b:2, c:3, d:4}

puts "1. #{h[:b]}"

h[:e] = 5
puts "2. #{h}"

h.filter! {|_, v| v >= 3.5 }
puts "3. #{h}"

puts "======================================================="
# Can hash values be arrays? Can you have an array of hashes? (give examples)

puts "Hash values can be arrays. For example:"
h = {foo: [0, 1, 2]}
p h

puts "We can also have an array of hashes. For example:"
h1 = {bat: 3, bar: 4}
h2 = {bam: 5, bat: 6}
p [h, h1, h2]

puts "======================================================="
# Given the following data structures, write a program that copies the information from the array into the empty hash that applies to the correct person.
# contact_data = [["joe@email.com", "123 Main st.", "555-123-4567"],
#             ["sally@email.com", "404 Not Found Dr.", "123-234-3454"]]
# contacts = {"Joe Smith" => {}, "Sally Johnson" => {}}
# Expected output:
#  {
#    "Joe Smith"=>{:email=>"joe@email.com", :address=>"123 Main st.", :phone=>"555-123-4567"},
#    "Sally Johnson"=>{:email=>"sally@email.com", :address=>"404 Not Found Dr.",  :phone=>"123-234-3454"}
#  }

contact_data = [["joe@email.com", "123 Main st.", "555-123-4567"],
            ["sally@email.com", "404 Not Found Dr.", "123-234-3454"]]
contacts = {"Joe Smith" => {}, "Sally Johnson" => {}}

contacts["Joe Smith"][:email] = contact_data[0][0]
contacts["Joe Smith"][:address] = contact_data[0][1]
contacts["Joe Smith"][:phone] = contact_data[0][2]
contacts["Sally Johnson"][:email] = contact_data[1][0]
contacts["Sally Johnson"][:address] = contact_data[1][1]
contacts["Sally Johnson"][:phone] = contact_data[1][2]

p contacts

puts "======================================================="
# Using the hash you created from the previous exercise, demonstrate how you would access Joe's email and Sally's phone number.

puts "Joe's email: #{contacts["Joe Smith"][:email]}"

puts "Sally's phone number: #{contacts["Sally Johnson"][:phone]}"

puts "======================================================="
# Use Ruby's Array method delete_if and String method start_with? to delete all of the strings that begin with an "s" in the following array.
# arr = ['snow', 'winter', 'ice', 'slippery', 'salted roads', 'white trees']
# Then recreate the arr and get rid of all of the strings that start with "s" or start with "w".

arr = ['snow', 'winter', 'ice', 'slippery', 'salted roads', 'white trees']

puts "Delete all of the strings that begin with an 's' in the array - `['snow', 'winter', 'ice', 'slippery', 'salted roads', 'white trees']`:"
p arr.delete_if { |word| word.start_with?("s") }

puts "Get rid of all of the strings that start with 's' or start with 'w' in the same array above:"
p arr.delete_if { |word| word.start_with?("s") || word.start_with?("w")  }

puts "======================================================="
# Take the following array:
# a = ['white snow', 'winter wonderland', 'melting ice',
#   'slippery sidewalk', 'salted roads', 'white trees']
# and turn it into a new array that consists of strings containing one word. (ex. ["white snow", etc...] → ["white", "snow", etc...]. Look into using Array's map and flatten methods, as well as String's split method.

a = ['white snow', 'winter wonderland', 'melting ice', 'slippery sidewalk', 'salted roads', 'white trees']
p a.map { |value| value.split(" ") }.flatten

puts "======================================================="
# What will the following program output?
# hash1 = {shoes: "nike", "hat" => "adidas", :hoodie => true}
# hash2 = {"hat" => "adidas", :shoes => "nike", hoodie: true}
# if hash1 == hash2
#   puts "These hashes are the same!"
# else
#   puts "These hashes are not the same!"
# end

puts "It will output the following message: `These hashes are the same!` because the key-value pair order doesn't matter in hash comparison."

puts "======================================================="
# Challenge: In exercise 11, we manually set the contacts hash values one by one. Now, programmatically loop or iterate over the contacts hash from exercise 11, and populate the associated data from the contact_data array. Hint: you will probably need to iterate over ([:email, :address, :phone]), and some helpful methods might be the Array shift and first methods.
# Note that this exercise is only concerned with dealing with 1 entry in the contacts hash, like this:
# contact_data = ["joe@email.com", "123 Main st.", "555-123-4567"]
# contacts = {"Joe Smith" => {}}
# As a bonus, see if you can figure out how to make it work with multiple entries in the contacts hash.

puts "Single contact entry:"
contact_data = ["joe@email.com", "123 Main st.", "555-123-4567"]
contacts = {"Joe Smith" => {}}
fields = [:email, :address, :phone]
contacts.each do |name, info_hash|
  fields.each_index do |index|
    info_hash[fields[index]] = contact_data[index]
  end
end
p contacts

puts "Mutliple contact entries like in exercies 11:"
contact_data = [["joe@email.com", "123 Main st.", "555-123-4567"],
            ["sally@email.com", "404 Not Found Dr.", "123-234-3454"]]
contacts = {"Joe Smith" => {}, "Sally Johnson" => {}}
fields = [:email, :address, :phone]
contact_keys = contacts.keys
contacts.each_with_index do |(name, info_hash), contact_index|
  fields.each_index do |field_index|
    info_hash[fields[field_index]] = contact_data[contact_index][field_index]
  end
end
p contacts
