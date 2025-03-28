def run14
  numbers = [1, 2, 3, 4, 5, 6]
  p numbers.select { |number| number.even? }.reverse
end
