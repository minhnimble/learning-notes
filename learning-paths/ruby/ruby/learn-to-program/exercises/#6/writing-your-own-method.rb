def englishNumber number
  if number < 0  # No negative numbers.
    return 'Please enter a number that isn\'t negative.'
  end
  if number == 0
    return 'zero'
  end

  # No more special cases! No more returns!

  numString = ''  # This is the string we will return.

  onesPlace = ['one',     'two',       'three',    'four',     'five',
               'six',     'seven',     'eight',    'nine']
  tensPlace = ['ten',     'twenty',    'thirty',   'forty',    'fifty',
               'sixty',   'seventy',   'eighty',   'ninety']
  teenagers = ['eleven',  'twelve',    'thirteen', 'fourteen', 'fifteen',
               'sixteen', 'seventeen', 'eighteen', 'nineteen']

  # "left" is how much of the number we still have left to write out.
  # "write" is the part we are writing out right now.
  # write and left... get it?  :)
  left  = number
  write = left/100          # How many hundreds left to write out?
  left  = left - write*100  # Subtract off those hundreds.

  if write > 0
    # Now here's a really sly trick:
    hundreds  = englishNumber write
    numString = numString + hundreds + ' hundred'
    # That's called "recursion". So what did I just do?
    # I told this method to call itself, but with "write" instead of
    # "number". Remember that "write" is (at the moment) the number of
    # hundreds we have to write out. After we add "hundreds" to
    # "numString", we add the string ' hundred' after it.
    # So, for example, if we originally called englishNumber with
    # 1999 (so "number" = 1999), then at this point "write" would
    # be 19, and "left" would be 99. The laziest thing to do at this
    # point is to have englishNumber write out the 'nineteen' for us,
    # then we write out ' hundred', and then the rest of
    # englishNumber writes out 'ninety-nine'.

    if left > 0
      # So we don't write 'two hundredfifty-one'...
      numString = numString + ' '
    end
  end

  write = left/10          # How many tens left to write out?
  left  = left - write*10  # Subtract off those tens.

  if write > 0
    if ((write == 1) and (left > 0))
      # Since we can't write "tenty-two" instead of "twelve",
      # we have to make a special exception for these.
      numString = numString + teenagers[left-1]
      # The "-1" is because teenagers[3] is 'fourteen', not 'thirteen'.

      # Since we took care of the digit in the ones place already,
      # we have nothing left to write.
      left = 0
    else
      numString = numString + tensPlace[write-1]
      # The "-1" is because tensPlace[3] is 'forty', not 'thirty'.
    end

    if left > 0
      # So we don't write 'sixtyfour'...
      numString = numString + '-'
    end
  end

  write = left  # How many ones left to write out?
  left  = 0     # Subtract off those ones.

  if write > 0
    numString = numString + onesPlace[write-1]
    # The "-1" is because onesPlace[3] is 'four', not 'three'.
  end

  # Now we just return "numString"...
  numString
end

puts "==================================================="
# Expand upon englishNumber. First, put in thousands. So it should return 'one thousand' instead of 'ten hundred' and 'ten thousand' instead of 'one hundred hundred'.
# Expand upon englishNumber some more. Now put in millions, so you get 'one million' instead of 'one thousand thousand'. Then try adding billions and trillions. How high can you go?
# P/S: I added `hundred` into the bigNumbers unit to cleanup repetitive code from the original function.

def englishNumber number
  if number < 0
    return 'Please enter a number that isn\'t negative.'
  end
  if number == 0
    return 'zero'
  end

  numString = ''

  onesPlace = ['one', 'two', 'three', 'four', 'five',
               'six', 'seven', 'eight', 'nine']
  tensPlace = ['ten', 'twenty', 'thirty', 'forty', 'fifty',
               'sixty', 'seventy', 'eighty', 'ninety']
  teenagers = ['eleven', 'twelve', 'thirteen', 'fourteen', 'fifteen',
               'sixteen', 'seventeen', 'eighteen', 'nineteen']

  # Larger units
  bigNumbers = [
    ['hundred', 100],
    ['thousand', 1000],
    ['million', 1000000],
    ['billion', 1000000000],
    ['trillion', 1000000000000]
  ]

  left = number

  # Handle larger units like thousand
  bigNumbers.reverse.each do |name, size|
    write = left / size
    left = left - write * size

    if write > 0
      prefix = englishNumber(write)
      numString = numString + prefix + ' ' + name

      if left > 0
        numString = numString + ' '
      end
    end
  end

  write = left / 10
  left = left - write * 10

  if write > 0
    if write == 1 && left > 0
      numString = numString + teenagers[left - 1]
      left = 0
    else
      numString = numString + tensPlace[write - 1]
    end

    if left > 0
      numString = numString + '-'
    end
  end

  write = left
  left = 0

  if write > 0
    numString = numString + onesPlace[write - 1]
  end

  numString
end

puts englishNumber(  0)
puts englishNumber(  9)
puts englishNumber( 10)
puts englishNumber( 11)
puts englishNumber( 17)
puts englishNumber( 32)
puts englishNumber( 88)
puts englishNumber( 99)
puts englishNumber(100)
puts englishNumber(101)
puts englishNumber(234)
puts englishNumber(3211)
puts englishNumber(999999)
puts englishNumber(1000000000000)

puts "==================================================="
# How about weddingNumber? It should work almost the same as englishNumber, except that it should insert the word "and" all over the place, returning things like 'nineteen hundred and seventy and two', or however wedding invitations are supposed to look. I'd give you more examples, but I don't fully understand it myself. You might need to contact a wedding coordinator to help you. 

def weddingNumber number
  if number < 0
    return 'Please enter a number that isn\'t negative.'
  end
  if number == 0
    return 'zero'
  end

  numString = ''

  onesPlace = ['one', 'two', 'three', 'four', 'five',
               'six', 'seven', 'eight', 'nine']
  tensPlace = ['ten', 'twenty', 'thirty', 'forty', 'fifty',
               'sixty', 'seventy', 'eighty', 'ninety']
  teenagers = ['eleven', 'twelve', 'thirteen', 'fourteen', 'fifteen',
               'sixteen', 'seventeen', 'eighteen', 'nineteen']

  # Larger units
  bigNumbers = [
    ['hundred', 100],
    ['thousand', 1000],
    ['million', 1000000],
    ['billion', 1000000000],
    ['trillion', 1000000000000]
  ]

  left = number

  # Handle larger units like thousand
  bigNumbers.reverse.each do |name, size|
    write = left / size
    left = left - write * size

    if write > 0
      prefix = englishNumber(write)
      numString = numString + prefix + ' ' + name

      if left > 0
        numString = numString + ' and '
      end
    end
  end

  write = left / 10
  left = left - write * 10

  if write > 0
    if write == 1 && left > 0
      numString = numString + teenagers[left - 1]
      left = 0
    else
      numString = numString + tensPlace[write - 1]
    end

    if left > 0
      numString = numString + '-'
    end
  end

  write = left
  left = 0

  if write > 0
    numString = numString + onesPlace[write - 1]
  end

  numString
end

puts weddingNumber(  0)
puts weddingNumber(  9)
puts weddingNumber( 10)
puts weddingNumber( 11)
puts weddingNumber( 17)
puts weddingNumber( 32)
puts weddingNumber( 88)
puts weddingNumber( 99)
puts weddingNumber(100)
puts weddingNumber(101)
puts weddingNumber(234)
puts weddingNumber(3211)
puts weddingNumber(999999)
puts weddingNumber(1000000000000)

puts "==================================================="
# "Ninety-nine bottles of beer..." Using englishNumber and your old program, write out the lyrics to this song the right way this time. Punish your computer: have it start at 9999. (Don't pick a number too large, though, because writing all of that to the screen takes your computer quite a while. A hundred thousand bottles of beer takes some time; and if you pick a million, you'll be punishing yourself as well!) 

def bottles_of_beer(n)
  if n <= 0
    puts "No more bottles of beer on the wall, no more bottles of beer."
    puts "We've taken them down and passed them around; now we're drunk and passed out!"
  else
    puts "#{englishNumber(n)} bottles of beer on the wall, #{englishNumber(n)} bottles of beer."
    puts "Take one down and pass it around, #{englishNumber(n-1)} bottles of beer on the wall."
  end
end

bottles_of_beer(9999)