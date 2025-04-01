def name
  puts "What is your name?"
  name = gets.chomp
  puts "Hi #{name}!"
end

def print_name_10_times
  puts "What is your name?"
  name = gets.chomp
  10.times do
    puts "Hi #{name}!"
  end
end

def full_name
  puts "What is your first name?"
  first_name = gets.chomp
  puts "What is your last name?"
  last_name = gets.chomp
  puts "#{first_name} #{last_name}"
end