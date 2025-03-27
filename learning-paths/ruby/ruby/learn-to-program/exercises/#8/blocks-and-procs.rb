# Grandfather Clock. Write a method which takes a block and calls it once for each hour that has passed today.
# That way, if I were to pass in the block do puts 'DONG!' end, it would chime (sort of) like a grandfather clock. Test your method out with a few different blocks (including the one I just gave you).
# Hint: You can use Time.now.hour to get the current hour. However, this returns a number between 0 and 23, so you will have to alter those numbers in order to get ordinary clock-face numbers (1 to 12).

def grandfather_clock(&block)
  current_hour = Time.now.hour % 12
  current_hour = 12 if current_hour == 0

  current_hour.times do |i|
    block.call(i) # Pass the index to the block
  end
end

# Test
dong_proc = Proc.new { puts 'DONG!' }
count_proc = Proc.new { |i| puts "Chime ##{i + 1}" }
message_proc = Proc.new { puts "Another hour has passed..." }

puts "Chiming the hour with 'DONG!'"
grandfather_clock(&dong_proc)

puts "\nCounting the hour with a number:"
grandfather_clock(&count_proc)

puts "\nPlaying a custom message:"
grandfather_clock(&message_proc)

puts "==================================================="
# Program Logger. Write a method called log, which takes a string description of a block and, of course, a block. Similar to doSelfImportantly, it should puts a string telling that it has started the block, and another string at the end telling you that it has finished the block, and also telling you what the block returned. Test your method by sending it a code block. Inside the block, put another call to log, passing another block to it. (This is called nesting.) In other words, your output should look something like this:
#
# Beginning "outer block"...
# Beginning "some little block"...
# ..."some little block" finished, returning:  5
# Beginning "yet another block"...
# ..."yet another block" finished, returning:  I like Thai food!
# ..."outer block" finished, returning:  false

def log(description, &block)
  puts "Beginning \"#{description}\"..."
  result = block.call
  puts "...\"#{description}\" finished, returning: #{result}"
end

# Test
log 'outer block' do
  log 'some little block' do
    5
  end

  log 'yet another block' do
    'I like Thai food!'
  end

  false
end

puts "==================================================="
# Better Logger. The output from that last logger was kind of hard to read, and it would just get worse the more you used it. It would be so much easier to read if it indented the lines in the inner blocks. To do this, you'll need to keep track of how deeply nested you are every time the logger wants to write something. To do this, use a global variable, a variable you can see from anywhere in your code. To make a global variable, just precede your variable name with $, like these: $global, $nestingDepth, and $bigTopPeeWee. In the end, your logger should output code like this:
# Beginning "outer block"...
#   Beginning "some little block"...
#     Beginning "teeny-tiny block"...
#     ..."teeny-tiny block" finished, returning:  lots of love
#   ..."some little block" finished, returning:  42
#   Beginning "yet another block"...
#   ..."yet another block" finished, returning:  I love Indian food!
# ..."outer block" finished, returning:  true

$nesting_depth = 0

def better_log(description, &block)
  indent = '  ' * $nesting_depth
  puts "#{indent}Beginning \"#{description}\"..."
  $nesting_depth += 1

  result = block.call

  $nesting_depth -= 1
  puts "#{indent}...\"#{description}\" finished, returning: #{result}"
end

# Test
better_log 'outer block' do
  better_log 'some little block' do
    better_log 'teeny-tiny block' do
      'lots of love'
    end
    42
  end

  better_log 'yet another block' do
    'I love Indian food!'
  end

  true
end