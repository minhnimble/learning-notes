def age
  puts "How old are you?"
  age_str = gets.chomp
  age_int = age_str.to_i
  puts "In 10 years you will be:"
  puts age_int += 10
  puts "In 20 years you will be:"
  puts age_int += 10
  puts "In 30 years you will be:"
  puts age_int += 10
  puts "In 40 years you will be:"
  puts age_int += 10
end