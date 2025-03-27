# Make an OrangeTree class.
# It should have a height method which returns its height, and a oneYearPasses method, which, when called, ages the tree one year.
# Each year the tree grows taller (however much you think an orange tree should grow in a year), and after some number of years (again, your call) the tree should die.
# For the first few years, it should not produce fruit, but after a while it should, and I guess that older trees produce more each year than younger trees... whatever you think makes most sense.
# And, of course, you should be able to countTheOranges (which returns the number of oranges on the tree), and pickAnOrange (which reduces the @orangeCount by one and returns a string telling you how delicious the orange was, or else it just tells you that there are no more oranges to pick this year). 
# Make sure that any oranges you don't pick one year fall off before the next year.

class OrangeTree

  def initialize
    @age = 0
    @height = 0
    @orange_count = 0
    @alive = true
  end

  def height
    unless @alive
      puts "The tree is dead"
      return
    end

    puts "The tree's height: #@height"
  end

  def count_the_oranges
    unless @alive
      puts "The tree is dead"
      return
    end

    puts "The tree's orange count: #@orange_count"
  end

  def pick_an_orange
    unless @alive
      puts "The tree is dead"
      return
    end

    if @orange_count > 0
      @orange_count -= 1
      puts "You pick a delicious orange"
    else
      puts "There are no more oranges to pick this year"
    end
  end

  def one_year_passes
    unless @alive
      puts "The tree is dead"
      return
    end

    @age += 1 # The tree is 1 year older

    max_alive_age = 20

    if @age > max_alive_age # The tree will die when it reach 21 years old
      @alive = false
      puts "The tree has died after living a long and fruitful life."
      return
    else
      @height += 0.5 # Tree grows 0.5 meters each year
      puts "The tree is #{@age} years old and #{@height.round(1)} meters tall."
    end

    start_produce_orange_age = 4
    start_materity_age = 10
    orange_increment_threshold_during_grown_up = 5

    @orange_count = 0 # All oranges fall off the tree before new year

    if @age >= start_produce_orange_age && @age < start_materity_age
      @orange_count = (@age - start_produce_orange_age + 1) * orange_increment_threshold_during_grown_up # Produce 5 more oranges each year during grown up
    elsif @age >= start_materity_age && @age <= max_alive_age
      @orange_count = orange_increment_threshold_during_grown_up * (start_materity_age - start_produce_orange_age + 1) # Cap orange production at 35 after maturity
    end

    return

  end

end

tree = OrangeTree.new
puts tree.one_year_passes
puts tree.one_year_passes
puts tree.height
puts tree.count_the_oranges
puts tree.one_year_passes
puts tree.one_year_passes
puts tree.count_the_oranges
puts tree.pick_an_orange
puts tree.count_the_oranges
puts tree.one_year_passes
puts tree.count_the_oranges
puts tree.one_year_passes
20.times { puts tree.one_year_passes }

puts "==================================================="
# Write a program so that you can interact with your baby dragon. You should be able to enter commands like feed and walk, and have those methods be called on your dragon.
# Of course, since what you are inputting are just strings, you will have to have some sort of method dispatch, where your program checks which string was entered, and then calls the appropriate method.

class Dragon
  def initialize(name)
    @name = name

    puts "#{@name} is born."
  end

  def feed
    puts "You feed #{@name}."
  end

  def walk
    puts "You walk #{@name}."
  end
end

# Create the dragon
puts "What would you like to name your dragon?"
name = gets.chomp
pet = Dragon.new(name)

# Command
while true
  puts
  puts "Enter a command: feed, walk, or exit"
  command = gets.chomp.downcase

  case command
  when "feed"
    pet.feed
  when "walk"
    pet.walk
  when "exit"
    puts "Goodbye!"
    break
  else
    puts "Invalid command. Try again."
  end
end
