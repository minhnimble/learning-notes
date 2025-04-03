# Exercises

1. Preparation - https://launchschool.com/books/ruby/read/preparations#aboutexercises

Result log from Terminal:
```bash
minhpham@Mikes-MBP ruby-programming % mkdir my_folder
minhpham@Mikes-MBP exercises % cd my_folder
minhpham@Mikes-MBP my_folder % touch one.rb
minhpham@Mikes-MBP my_folder % touch two.rb
minhpham@Mikes-MBP my_folder % ruby one.rb
minhpham@Mikes-MBP my_folder % ruby one.rb
this is file one
minhpham@Mikes-MBP my_folder % ruby two.rb
this is file two
```

2. The Basics - https://launchschool.com/books/ruby/read/basics#exercises

Result log from Terminal:
```bash
minhpham@Mikes-MBP /#2 % ruby the-basics.rb
John Doe
=======================================================
4
3
2
1
=======================================================
1975
2004
2013
2001
1981
=======================================================
1975
2004
2013
2001
1981
=======================================================
120
720
5040
40320
=======================================================
9.8596
32.1489
102.61690000000002
=======================================================
The error is because we are providing a ) wrongly in a place where it needs a }, for example this following code will trigger the error:
test_dict = "Test 1" => 1, "Test 2" => 2 )
```

3. Variables - https://launchschool.com/books/ruby/read/variables#exercises

Result log from Terminal:
```bash
minhpham@Mikes-MBP /#3 % ruby variables.rb
What is your name?
Mike
Hi Mike!
=======================================================
How old are you?
34
In 10 years you will be:
44
In 20 years you will be:
54
In 30 years you will be:
64
In 40 years you will be:
74
=======================================================
What is your name?
Mike
Hi Mike!
Hi Mike!
Hi Mike!
Hi Mike!
Hi Mike!
Hi Mike!
Hi Mike!
Hi Mike!
Hi Mike!
Hi Mike!
=======================================================
What is your first name?
Mike
What is your last name?
Pham
Mike Pham
=======================================================
The 1st case - x will print '3'
The 2nd case - x will also print '3'
No error for both cases, because:
For the 1st case, += will modify the x value directly and after the last time run for the times block, the x value will equal 3
For the 2nd case, x will be updated with the new y value for each time run in the times block, and the last x assignment will be to y which equals to 3
```

4. Methods - https://launchschool.com/books/ruby/read/methods#exercises

Result log from Terminal:
```bash
minhpham@Mikes-MBP /#4 % ruby methods.rb
Hi Mike!
=======================================================
1. it will print 2
2. it will print nil
3. it will print 'Joe'
4. it will print 'four'
4. it will print nil
=======================================================
50
=======================================================
It doesn't print anything since the 'return' call happens before the 'puts words' call to print out something.
=======================================================
Now when calling 'scream("Yippeee")', it will print the following message:
Yippeee!!!!
=======================================================
When calling a method called `calculate_product` that requires `two` arguments, but we are only providing `one``. 
```

5. Flow Control - https://launchschool.com/books/ruby/read/flow_control#exercises

Result log from Terminal:
```bash
minhpham@Mikes-MBP /#5 % ruby flow-control.rb
'(32 * 4) >= 129' returns 'false'
'false != !true' returns 'false'
'true == 4' returns 'false'
'false == (847 == '847')' returns 'true'
'(!true || (!(100 / 5) == 20) || ((328 / 4) == 82)) || false' returns 'true'
=======================================================
HELLO WORLD
test
=======================================================
Provide a number:
6
This number is between 0 and 50
=======================================================
Snippet 1 will print 'FALSE'
Snippet 2 will print 'Did you get it right?'
Snippet 3 will print 'Alright now!'
=======================================================
Error reason: missing 1 end for the if else clause. The function is fixed and working as follow:
nope
=======================================================
`(32 * 4) >= "129"` raises an error - comparison of Integer with String failed
`847 == '847'` returns `false`
`'847' < '846'` returns `false`
`'847' > '846'` returns `true`
`'847' > '8478'` returns `false`
`'847' < '8478'` returns `true`
```

6. Loops & Iterators - https://launchschool.com/books/ruby/read/loops_iterators#exercises

Result log from Terminal:
```bash
minhpham@Mikes-MBP /#6 % ruby loops-and-iterators.rb
It only increases each number in the x array to 1 but no assignment, thus it will print the x array as the same in the end - `[1, 2, 3, 4, 5]`.
=======================================================
Type something:
SLEEP
Perform SLEEP action!
Type something:
CRY
Perform CRY action!
Type something:
RUN
Perform RUN action!
Type something:
EAT
Perform EAT action!
Type something:
Stop
Perform Stop action!
Type something:
STOP
=======================================================
Starting the count down...
40
39
38
37
36
35
34
33
32
31
30
29
28
27
26
25
24
23
22
21
20
19
18
17
16
15
14
13
12
11
10
9
8
7
6
5
4
3
2
1
0
Countdown completed!
```

7. Arrays - https://launchschool.com/books/ruby/read/arrays#exercises

Result log from Terminal:
```bash
minhpham@Mikes-MBP /#7 % ruby arrays.rb
true
=======================================================
1. [["b"], ["b", 2], ["b", 3], ["a", 1], ["a", 2], ["a", 3]]
2. [["b"], ["a", [1, 2, 3]]]
=======================================================
example
=======================================================
With the following arr - `arr = [15, 7, 18, 5, 12, 8, 5, 1]`
1. arr.index(5) returns 3
2. arr.index[5] returns error - undefined method '[]'
2. arr[5] returns 8
=======================================================
a is 'e'
b is 'A'
c is nil
=======================================================
Error reason: the code provides a string instead of an integer index to access an array element. The code is fixed and working as follow:
["bob", "joe", "susan", "jody"]
=======================================================
Index: 0, Value: 1
Index: 1, Value: 2
Index: 2, Value: 3
Index: 3, Value: 4
Index: 4, Value: 5
Index: 5, Value: 6
Index: 6, Value: 7
Index: 7, Value: 8
Index: 8, Value: 9
Index: 9, Value: 10
=======================================================
[1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12]
[3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14]
```

8. Hashes - https://launchschool.com/books/ruby/read/hashes#exercises

Result log from Terminal:
```bash
minhpham@Mikes-MBP \#8 % ruby hashes.rb
["jane", "jill", "beth", "frank", "rob", "david"]
=======================================================
`Merge` returns the new Hash formed by merging each of other_hashes into a copy of self. For example:
- Merged hash: {foo: 0, bar: 4, baz: 2, bat: 3}
- Orginal hash after merge: {foo: 0, bar: 1, baz: 2}
`Merge!` Merges each of other_hashes into self; returns self. For example:
- Orginal hash before merge: {foo: 0, bar: 1, baz: 2}
- Orginal hash after merge: {foo: 0, bar: 1, baz: 2, bam: 5, bat: 6}
=======================================================
Loops through a hash and prints all of the keys:
foo
bar
baz
Loops through a hash and prints all of the values:
0
1
2
Loops through a hash and prints all both:
Key: foo Value: 0
Key: bar Value: 1
Key: baz Value: 2
=======================================================
Bob
=======================================================
Check the following hash - `{foo: 0, bar: 1, baz: 2}` if it has 3 as a value:
false
Check the hash if it has 2 as a value:
true
=======================================================
`my_hash` has the key as symbol - :x.
`my_hash2` has the key as string value - "hi there".
=======================================================
The answer is B. There is no method called keys for Array objects.
```

9. More Stuff - https://launchschool.com/books/ruby/read/more_stuff#exercises

Result log from Terminal:
```bash
minhpham@Mikes-MBP \#9 % ruby more-stuff.rb
laboratory
elaborate
=======================================================
The program will return a Proc object and print nothing. Need to activate the Proc object with the `.call` method
=======================================================
Exception handling is a structure used to handle the possibility of an error occurring in a program.
It is a way of handling the error by changing the flow of control without exiting the program entirely.
=======================================================
Hello from inside the execute method!
=======================================================
The `block`` param misses the ampersand sign `&` that allows a block to be passed as a parameter.
minhpham@Mikes-MBP \#9 % ruby more-stuff.rb
laboratory
elaborate
=======================================================
The program will return a Proc object and puts nothing. Need to activate the Proc object with the `.call` method to print out the provided message.
=======================================================
Exception handling is a structure used to handle the possibility of an error occurring in a program.
It is a way of handling the error by changing the flow of control without exiting the program entirely.
=======================================================
Hello from inside the execute method!
=======================================================
The `block` param misses the ampersand sign `&` that allows a block to be passed as a parameter.

```

10. Intro Exercises - https://launchschool.com/books/ruby/read/intro_exercises

Result log from Terminal:
```bash
minhpham@Mikes-MBP /#10 % ruby intro-exercises.rb
1
2
3
4
5
6
7
8
9
10
=======================================================
6
7
8
9
10
=======================================================
[1, 3, 5, 7, 9]
=======================================================
[0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11]
=======================================================
[0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 3]
=======================================================
[0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
=======================================================
Array has only values, Hash has a pair of keys and values.
=======================================================
{foo: 0, bar: 1, baz: 2}
{foo: 0, bar: 1, baz: 2}
=======================================================
1. 2
2. {a: 1, b: 2, c: 3, d: 4, e: 5}
3. {d: 4, e: 5}
=======================================================
Hash values can be arrays. For example:
{foo: [0, 1, 2]}
We can also have an array of hashes. For example:
[{foo: [0, 1, 2]}, {bat: 3, bar: 4}, {bam: 5, bat: 6}]
=======================================================
{"Joe Smith" => {email: "joe@email.com", address: "123 Main st.", phone: "555-123-4567"}, "Sally Johnson" => {email: "sally@email.com", address: "404 Not Found Dr.", phone: "123-234-3454"}}
=======================================================
Joe's email: joe@email.com
Sally's phone number: 123-234-3454
=======================================================
Delete all of the strings that begin with an 's' in the array - `['snow', 'winter', 'ice', 'slippery', 'salted roads', 'white trees']`:
["winter", "ice", "white trees"]
Get rid of all of the strings that start with 's' or start with 'w' in the same array above:
["ice"]
=======================================================
["white", "snow", "winter", "wonderland", "melting", "ice", "slippery", "sidewalk", "salted", "roads", "white", "trees"]
=======================================================
It will output the following message: `These hashes are the same!` because the key-value pair order doesn't matter in hash comparison.
=======================================================
Single contact entry:
{"Joe Smith" => {email: "joe@email.com", address: "123 Main st.", phone: "555-123-4567"}}
Mutliple contact entries like in exercies 11:
{"Joe Smith" => {email: "joe@email.com", address: "123 Main st.", phone: "555-123-4567"}, "Sally Johnson" => {email: "sally@email.com", address: "404 Not Found Dr.", phone: "123-234-3454"}}
```
