# Given a hash of family members, with keys as the title and an array of names as the values, use Ruby's built-in select method to gather only siblings' names into a new array.
# family = {  uncles: ["bob", "joe", "steve"],
#   sisters: ["jane", "jill", "beth"],
#   brothers: ["frank","rob","david"],
#   aunts: ["mary","sally","susan"]
# }

family = {  uncles: ["bob", "joe", "steve"],
  sisters: ["jane", "jill", "beth"],
  brothers: ["frank","rob","david"],
  aunts: ["mary","sally","susan"]
}

siblings = []
family.each do |k, v|
  if k == :sisters || k == :brothers
    siblings << v
  end
end

p siblings.flatten

puts "======================================================="
# Look at Ruby's [merge method](https://docs.ruby-lang.org/en/3.2/Hash.html#method-i-merge). Notice that it has two versions. What is the difference between merge and merge!? Write a program that uses both and illustrate the differences.

puts "`Merge` returns the new Hash formed by merging each of other_hashes into a copy of self. For example:" 
h = {foo: 0, bar: 1, baz: 2}
h1 = {bat: 3, bar: 4}
puts "- Merged hash: #{h.merge(h1)}"
puts "- Orginal hash after merge: #{h}"

puts "`Merge!` Merges each of other_hashes into self; returns self. For example:"
h2 = {bam: 5, bat: 6}
puts "- Orginal hash before merge: #{h}"
h.merge!(h2)
puts "- Orginal hash after merge: #{h}"

puts "======================================================="
# Using some of Ruby's built-in [Hash methods](https://docs.ruby-lang.org/en/3.2/Hash.html), write a program that loops through a hash and prints all of the keys. Then write a program that does the same thing except printing the values. Finally, write a program that prints both.

dict = {foo: 0, bar: 1, baz: 2}

puts "Loops through a hash and prints all of the keys:"
dict.each_key { |k| puts k }

puts "Loops through a hash and prints all of the values:"
dict.each_value { |v| puts v }

puts "Loops through a hash and prints all both:"
dict.each { |k, v| puts "Key: #{k} Value: #{v}" }

puts "======================================================="
# Given the following expression, how would you access the name of the person?
# person = {name: 'Bob', occupation: 'web developer', hobbies: 'painting'}

person = {name: 'Bob', occupation: 'web developer', hobbies: 'painting'}
puts person[:name]

puts "======================================================="
# What method could you use to find out if a Hash contains a specific value in it? Write a program that verifies that the value is within the hash.

puts "Check the following hash - `{foo: 0, bar: 1, baz: 2}` if it has 3 as a value:"
puts dict.value?(3)

puts "Check the hash if it has 2 as a value:"
puts dict.value?(2)

puts "======================================================="
# Given the following code...
# x = "hi there"
# my_hash = {x: "some value"}
# my_hash2 = {x => "some value"}
# What's the difference between the two hashes that were created?

puts "`my_hash` has the key as symbol - :x."
puts "`my_hash2` has the key as string value - \"hi there\"."

puts "======================================================="
# If you see this error, what do you suspect is the most likely problem?
#   NoMethodError: undefined method `keys' for Array
#   A. We're missing keys in an array variable.
#   B. There is no method called keys for Array objects.
#   C. keys is an Array object, but it hasn't been defined yet.
#   D. There's an array of strings, and we're trying to get the string keys out of the array, but it doesn't exist.

puts "The answer is B. There is no method called keys for Array objects."
