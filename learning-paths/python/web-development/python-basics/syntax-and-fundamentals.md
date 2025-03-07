# Variables & Data Types (int, str, float, bool, list, dict, tuple)

## Numbers

Division (/) always returns a float. To do [floor division](https://docs.python.org/3/glossary.html#term-floor-division) and get an integer result you can use the // operator

```python
>>> 17 // 3  # floor division discards the fractional part
5
```

With Python, it is possible to use the ** operator to calculate powers:

```python
>>> 5 ** 2  # 5 squared
25
>>> 2 ** 7  # 2 to the power of 7
128
```

In interactive mode, the last printed expression is assigned to the variable `_`. This means that when you are using Python as a desk calculator, it is somewhat easier to continue calculations, for example:

```python
>>> tax = 12.5 / 100
>>> price = 100.50
>>> price * tax
12.5625
>>> price + _
113.0625
>>> round(_, 2)
113.06
```

## Text

If you don’t want characters prefaced by \ to be interpreted as special characters, you can use raw strings by adding an `r` before the first quote:

```python
>>> print('C:\some\name')  # here \n means newline!
C:\some
ame
>>> print(r'C:\some\name')  # note the r before the quote
C:\some\name
```
Strings can be concatenated (glued together) with the + operator, and repeated with *:

```python
>>> 3 * 'un' + 'ium' # 3 times 'un', followed by 'ium'
'unununium'
```

Two or more string literals (i.e. the ones enclosed between quotes) next to each other are automatically concatenated.

```python
>>> 'Py' 'thon'
'Python'
```

Strings can be indexed (subscripted), and indices may also be negative numbers, to start counting from the right:

```python
>>> word = 'Python'
>>> word[0]  # character in position 0
'P'
>>> word[-1]  # last character
'n'
>>> word[-2]  # second-last character
'o'
```

In addition to indexing, slicing is also supported. While indexing is used to obtain individual characters, slicing allows you to obtain a substring. Slice indices have useful defaults; an omitted first index defaults to zero, an omitted second index defaults to the size of the string being sliced:

```python
>>> word[2:5]  # characters from position 2 (included) to 5 (excluded)
'tho'
>>> word[:2]   # character from the beginning to position 2 (excluded)
'Py'
>>> word[4:]   # characters from position 4 (included) to the end
'on'
>>> word[-2:]  # characters from the second-last (included) to the end
'on'
```

The built-in function len() returns the length of a string:

```python
>>> s = 'supercalifragilisticexpialidocious'
>>> len(s)
34
```

## Lists

It is possible to nest lists (create lists containing other lists), for example:

```python
>>> a = ['a', 'b', 'c']
>>> n = [1, 2, 3]
>>> x = [a, n]
>>> x
[['a', 'b', 'c'], [1, 2, 3]]
>>> x[0]
['a', 'b', 'c']
>>> x[0][1]
'b'
```

# Operators (arithmetic, comparison, logical)


# Control Flow (if-else, loops: for/while)

## `if` Statements

```python
>>> x = int(input("Please enter an integer: "))
Please enter an integer: 42
>>> if x < 0:
...    x = 0
...    print('Negative changed to zero')
...elif x == 0:
...    print('Zero')
...elif x == 1:
...    print('Single')
...else:
...    print('More')
More
```

## `for` Statements

```python
>>> words = ['cat', 'window', 'defenestrate']
>>> for w in words:
...    print(w, len(w))
...
cat 3
window 6
defenestrate 12
```

## The [range()](https://docs.python.org/3/library/stdtypes.html#range) Function

```python
>>> for i in range(5):
...    print(i)
...
0
1
2
3
4
```

## `else` Clauses on Loops

In a `for` or `while` loop the break statement may be paired with an `else` clause. If the loop finishes without executing the `break` or `return`, the `else` clause executes.

```python
>>> for n in range(2, 10):
...    for x in range(2, n):
...        if n % x == 0:
...            print(n, 'equals', x, '*', n//x)
...            break
...    else:
...        print(n, 'is a prime number') # loop fell through without finding a factor
...
2 is a prime number
3 is a prime number
4 equals 2 * 2
5 is a prime number
6 equals 2 * 3
7 is a prime number
8 equals 2 * 4
9 equals 3 * 3
```
## `pass` Statements

The `pass` statement does nothing. It can be used when a statement is required syntactically but the program requires no action. For example:

```python
>>>def initlog(*args):
...    pass   # Remember to implement this!
...
```

## `match` Statements

```python
def http_error(status):
    match status:
        case 400:
            return "Bad request"
        case 404:
            return "Not found"
        case 418:
            return "I'm a teapot"
        case 401 | 403:
            return "Not allowed"
        case _:
            return "Something's wrong with the internet"
```

# Functions (definition, arguments, return)