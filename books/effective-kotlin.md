# Introduction: Be pragmatic

1. Since the beginning, Kotlin was created and designed to be a general-purpose programming language, suitable for large applications.
2. The creators of Kotlin are taking their time. Development of Kotlin started in 2010, and the first officially stable version was released in February of 2016. During this period, a lot has changed. If you find some code from the first proposals, it looks almost nothing like Kotlin today.

Kotlin was created as a pragmatic language for practical applications. The Kotlin team always trying to understand the strengths and weaknesses of other languages and build on them.

## The philosophy of Kotlin

The central point of Kotlin’s philosophy is pragmatism. All choices need to serve business needs, like:
* Productivity - application production is fast.
* Scalability - with application growth, its development does not become more expensive. It may even get cheaper.
* Maintainability - maintenance is easy.
* Reliability - applications behave as expected, and there are fewer errors.
* Efficiency - the application runs fast and needs fewer resources (memory, processor, etc.).

## The purpose of this book

Explain how to use different Kotlin features to achieve safe, readable, scalable, and efficient code.

# Part 1: Good code

## Chapter 1: Safety

### Item 1: Limit mutability

Holding state is a double-edged sword. On one hand it is very useful because it makes it possible to represent elements changing over time, but on the other hand state management is hard, because:
1. It is harder to understand and debug a program with many mutating points. The relationship between these mutations needs to be understood, and it is harder to track how they changed when there are more of them. A class with many mutating points that depend on each other is often really hard to understand and to modify. It is especially problematic in case of unexpected situations or errors.
2. Mutability makes it harder to reason about the code. State of immutable element is clear. Mutable state is much harder to comprehend. It is harder to reason what is its value as it might change at any point and just because we checked in some moment it doesn’t mean it is still the same.
3. It requires proper synchronization in multithreaded programs. Every mutation is a potential conflict.
4. Mutable elements are harder to test. We need to test every possible state, and the more mutability, the more states there are to test. What is more, the number of states we need to test generally grows exponentially with the number of mutation points in the same object or file, as we need to test all different combinations of possible states.
5. When state mutates, often some other classes need to be notified about this change. For instance, when we add a mutable element to a sorted list, once the element is changed, we need to sort this list again.

-> Need to implement proper synchronization like the one presented below.

```kotlin
val lock = Any() 
var num = 0 
for (i in 1..1000) {
  thread {
    Thread.sleep(10)
    synchronized(lock) {
      num += 1
    }
  }
}

Thread.sleep(1000)
print(num) //1000
```

**Limiting mutability in Kotlin**

_Read-only properties val_

Smart cast is impossible for the below fullName because it is defined using getter, so it might give a different value during check and different later during use.

```kotlin
val name: String? = "Márton" 
val surname: String = "Braun"
val fullName: String?
  get() = name?.let { "$it $surname" }
val fullName2: String? = name?.let { "$it$surname" }

fun main() {
  if (fullName != null) {
    println(fullName.length) // ERROR
  }
  if (fullName2 != null) { 
    println(fullName2.length) // Márton Braun
  } 
}
```
_Separation between mutable and read-only collections_

Down-casting read-only collections to mutable should never take place in Kotlin. For example:
```kotlin
val list = listOf(1,2,3)

if (list is MutableList) { // DON’T DO THIS!
  list.add(4)
}
```
If you need to change from read-only to mutable, you should use `List.toMutableList` function, which creates a copy that you can then modify.

_Copy in data classes_

Prefer less mutability, immutable objects have their own advantages:
1. They are easier to reason about since their state stays the same once they are created.
2. Immutability makes it easier to parallelize the program as there are no conflicts among shared objects.
3. References to immutable objects can be cached as they are not going to change.
4. We do not need to make defensive copies on immutable objects. When we do copy immutable objects, we do not need to make it a deep copy.
5. Immutable objects are the perfect material to construct other objects. Both mutable and immutable. We can still decide where mutability takes place, and it is easier to operate on immutable objects.
6. We can add them to set or use them as keys in maps, in opposition to mutable objects that shouldn’t be used this way. This is because both those collections use hash table under the hood in Kotlin/JVM, and when we modify elements already classified to a hash table, its classification might not be correct anymore and we won’t be able to find it. 

Use data modifier to represent a bundle of data. -> user.copy(surname="new surname")

_Different kinds of mutation points_

Using a mutable property instead of a mutable list allows us to track how this property changes when we define a custom setter or using a delegate. 
For read-only collections on mutable properties, it is also easier to control how they change - there is only a setter instead of multiple methods mutating this object, and we can make it private.
In short, using mutable collections is a slightly faster option, but using a mutable property instead gives us more control over how the object is changing.

_Do not leak mutation points_

It is a dangerous situation when we expose a mutable object that makes up state. It is especially dangerous when such modifications are accidental. 

There are two ways how we can deal with that:
+ The first one is copying returned mutable objects. We call that defensive copying:
```kotlin
class UserHolder {
  private val user: MutableUser()
  fun get(): MutableUser { return user.copy() }
}
```
+ Though whenever possible we prefer limiting mutability, and for collections we can do that by upcasting those objects to their read-only supertype:
```kotlin
class UserRepository {

  private val storedUsers: MutableMap<Int, String> = mutableMapOf()
  
  fun loadAll(): Map<Int, String> {
    return storedUsers
  }
}
```

Summary:

* Prefer val over var.
* Prefer an immutable property over a mutable one.
* Prefer objects and classes that are immutable over mutable.
* If you need them to change,consider making them immutable data classes, and using copy.
* When you hold state, prefer read-only over mutable collections.
* Design your mutation points wisely and do not produce unnecessary ones.
* Do not expose mutable objects.

Sometimes we prefer a mutable object because they are more efficient. Such optimizations should be preferred only in the performance critical parts of our code and when we use them, we need to remember that mutability requires more attention when we prepare it for multithreading. The baseline is that we should limit mutability.

### Item 2: Minimize the scope of variables

Prefer to tighten the scope of variables and properties by:
* Using local variables instead of properties.
* Using variables in the narrowest scope possible, so for instance, if a variable is used only inside a loop, defining it inside this loop.

When we tighten a variable’s scope, it is easier to keep our programs simple to track and manage.
Thinking about mutable properties, it is easier to track how they change when they can only be modified in a smaller scope.
Variables with a wider scope might be overused by another developer.
Whether a variable is read-only or read-write, we always prefer a variable to be initialized when it is defined.

_Capturing_

About Kotlin coroutines, one of my exercises is to implement the Sieve of Eratosthenes to find prime numbers using a sequence builder:

1. We take a list of numbers starting from 2.
2. We take the first one. It is a prime number.
3. From the rest of the numbers, we remove the first one and we filter out all the numbers that are divisible by this prime number.

Working code:
```kotlin
val primes: Sequence<Int> = sequence {
  var numbers = generateSequence(2) { it + 1 }
  while (true) {
    val prime = numbers.first() 
    yield(prime)
    numbers = numbers.drop(1).filter { it % prime != 0 }
  }
}
print(primes.take(10).toList()) //[2,3,5,7,11,13,17,19,23,29]
```

Capture `prime` code -> no longer working:
```kotlin
val primes: Sequence<Int> = sequence {
  var numbers = generateSequence(2) { it + 1 }
  var prime: Int
  while (true) {
    prime = numbers.first() 
    yield(prime)
    numbers = numbers.drop(1).filter { it % prime != 0 }
  }
}
print(primes.take(10).toList()) //[2,3,5,6,7,8,9,10,11,12]
```

The reason why we have such a result is that we captured the variable prime. Filtering is done lazily because we’re using a sequence. In every step, we add more and more filters. In the “optimized” one we always add the filter which references the mutable property prime. Therefore we always filter the last value of prime. Only dropping works and so we end up with consecutive numbers.

We should be aware of problems with unintentional capturing because such situations happen. To prevent them we should avoid mutability and prefer narrower scope for variables.

Summary:

* Prefer to define variables for the closest possible scope.
* Prefer val over var also for local variables.

### Item 3: Eliminate platform types as soon as possible

Platform type - a type that comes from another language and has unknown nullability.

```kotlin
// Java
public class JavaClass{ 
  public String getValue() {
    return null;
  }
}

//Kotlin
fun statedType() {
  val value: String = JavaClass().value 
  //...
  println(value.length)
}

fun platformType() {
  val value = JavaClass().value 
  //...
  println(value.length)
}
```

Summary:

* Eliminate platform types as soon as possible, and do not let them propagate.
* Specify types using annotations that specify nullability on exposed Java constructors, methods and fields.

### Item 4: Do not expose inferred types

When we have too restrictive type inferred, we just need to specify it

```kotlin
open class Animal

class Zebra: Animal()

fun main() {
  var animal: Animal = Zebra() 
  animal = Animal()
}
```

Summary:

* The general rule is that if we are not sure about the type, we should specify it.
* In an external API, we should always specify types.

### Item 5: Specify your expectations on arguments and state

When have expectations, declare them as soon as possible.
* `require` block - a universal way to specify expectations on arguments.
* `check` block - a universal way to specify expectations on the state.
* `assert` block - a universal way to check if something is true. Such checks on the JVM will be evaluated only on the testing mode.
* Elvis operator with `return` or `throw`.

Such declarative checks have many advantages:
* Expectations are visible even to those programmers who are not reading the documentation.
* If they are not satisfied, the function throws an exception instead of leading to unexpected behavior. It is important that these exceptions are thrown before the state is modified and so we will not have a situation where only some modifications are applied and others are not. Thanks to assertive checks, errors are harder to miss and our state is more stable.
* Code is to some degree self-checking. There is less of a need to be unit-tested when these conditions are checked in the code.
* All checks listed above work with smart-casting, so thanks to them there is less casting required.

#### Arguments

A few examples:
* When you calculate the factorial of a number, you might require this number to be a positive integer.
* When you look for clusters, you might require a list of points to not be empty.
* When you send an email to a user you might require that user to have an email, and this value to be a correct email address (assuming that user should check email correctness before using this function).

The most universal and direct Kotlin way to state those requirements is using the `require` function that checks this requirement and throws an exception if it is not satisfied. The require function is used when we specify requirements on arguments:

```kotlin
fun factorial(n: Int): Long {
  require(n >= 0) { "Cannot calculate factorial of $n " + 3 "because it is smaller than 0" }
  return if (n <= 1) 1 else factorial(n - 1) * n
}

fun findClusters(points: List<Point>): List<Cluster> { 
  require(points.isNotEmpty())
  //...
}

fun sendEmail(user: User, message: String){ 
  requireNotNull(user.email) 
  require(isValidEmail(user.email))
  //...
}
```

#### State

A few common examples:
* Some functions might need an object to be initialized first. 
* Actions might be allowed only if the user is logged in.
* Functions might require an object to be open.

The standard way to check if those expectations on the state are satisfied is to use the `check` function. We use it when we do not trust that our own implementation handles the state correctly:

```kotlin
fun speak(text:String) { 
  check(isInitialized) 
  //...
}

fun getUserInfo(): UserInfo { 
  checkNotNull(token)
  //...
}

fun next(): T { 
  check(isOpen) 
  //...
}
```

#### Assertions

The main advantages of having `assert` checks in functions instead of in unit tests are:
* Assertions make code self-checking and lead to more effective testing.
* Expectations are checked for every real use-case instead of for concrete cases.
* We can use them to check something at the exact point of execution.
* We make code fail early, closer to the actual problem. Thanks to that we can also easily find where and when the unexpected behavior started.

#### Nullability and smart casting

For nullability, it is also popular to use the Elvis operator with throw or return on the right side. Such a structure is also highly readable and at the same time, it gives us more flexibility in deciding what behavior we want to achieve.

Summary:

* Specify your expectations to:
  + Make them more visible.
  + Protect your application stability. 
  + Protect your code correctness.
  + Smart cast variables.
* Four main mechanisms we use for that are:
  + require block - a universal way to specify expectations on arguments.
  + check block - a universal way to specify expectations on the state.
  + assert block - a universal way to test in testing mode if something is true.
  + Elvis operator with return or throw.
* You might also use throw to throw a different error.

### Item 6: Prefer standard errors to custom ones

* `IndexOutOfBoundsException` - Indicate that the index parameter value is out of range. Used especially by collections and arrays. It is thrown for instance by ArrayList.get(Int).
* `ConcurrentModificationException` - Indicate that concurrent modification is prohibited and yet it has been detected.
* `UnsupportedOperationException` - Indicate that the declared method is not supported by the object. Such a situation should be avoided and when a method is not supported, it should not be present in the class.
* `NoSuchElementException` - Indicate that the element being requested does not exist. Used for instance when we implement Iterable and the client asks for next when there are no more elements.

### Item 7: Prefer null or Failure result when the lack of result is possible

Sometimes, a function cannot produce its desired result. A few common examples are:
* Get data from some server, but there is a problem with our internet connection.
* Get the first element that matches some criteria, but there is no such element in our list.
* Parse an object from the text, but this text is malformatted.

All exceptions indicate incorrect, special situations and should be treated this way. We should use exceptions only for exceptional conditions. This is why the rule is that we should prefer returning null or Failure when an error is expected, and throwing an exception when an error is not expected.

### Item 8: Handle nulls properly

`null` means a lack of value. For property, it might mean that the value was not set or that it was removed.

#### Handling nulls safely

The two safest and most popular ways to handle nulls is by using safe call and smart casting:

```kotlin
printer?.print() // Safecall
if (printer != null) printer.print() // Smartcasting
```

Defensive and offensive programming: 
- `Defensive programming` is a blanket term for various practices increasing code stability once the code is in production, often by defending against the currently impossible.
- `Offensive programming` is in case of an unexpected situation we complain about it loudly to inform the developer who led to such situation, and to force him or her to correct it. 

#### Throw an error

 When we have a strong expectation about something that isn’t met, it is better to throw an error to inform the programmer about the unexpected situation.

 #### The problems with the not-null assertion !!

 Not-null assertion !! is a lazy option. It throws a generic exception that explains nothing. It is also short and simple, which also makes it easy to abuse or misuse.

 Nobody can predict how code will evolve in the future, and if you use not-null assertion !! or explicit error throw, you should assume that it will throw an error one day.

 Rare cases where not-null assertion !! does make sense are mainly a result of common interoperability with libraries in which nullability is not expressed correctly.

#### Avoiding meaningless nullability

Nullability is a cost as it needs to be handled properly that we would then be tempted to use the unsafe not-null assertion !! or forced to repeat generic safe handling that only clutters the code.

#### `lateinit` property and `notNull` delegate

`lateinit` is a good practice when we are sure that a property will be initialized before the first use.

One case in which `lateinit` cannot be used is when we need to initialize a property with a type that, on JVM, associates to a primitive, like `Int`, `Long`, `Double` or `Boolean`. For such cases we have to use `Delegates.notNull` which is slightly slower, but supports those types.

```kotlin
class DoctorActivity: Activity() {
  private var doctorId: Int by Delegates.notNull() 
  private var fromNotification: Boolean by Delegates.notNull()
  // or
  private var doctorId: Int by arg(DOCTOR_ID_ARG) 
  private var fromNotification: Boolean by arg(FROM_NOTIFICATION_ARG)
  
  override fun onCreate(savedInstanceState: Bundle?) { 
    super.onCreate(savedInstanceState)
    doctorId = intent.extras.getInt(DOCTOR_ID_ARG) 
    fromNotification = intent.extras.getBoolean(FROM_NOTIFICATION_ARG)
  } 
}
```

### Item 9: Close resources with use

if we had errors from both the body of the `try` and from `finally` blocks, only one would be properly propagated. The behavior we should expect is for the information about the new error to be added to the previous one. The proper implementation of this is long and complicated, but it is also common and so it has been extracted into the `use` function from the standard library.

```kotlin
fun countCharactersInFile(path:String): Int { 
  BufferedReader(FileReader(path)).use { reader ->
    return reader.lineSequence().sumBy { it.length }
  }
}
```

As this support is often needed for files, and as it is common to read files line-by-line, there is also a `useLines` function:

```kotlin
fun countCharactersInFile(path:String): Int = 
  File(path).useLines { lines ->
    lines.sumBy { it.length }
  }
```

Summary:

* Operate on objects implementing `Closeable` or `AutoCloseable` using `use`.
* Operate on a file, consider `useLines` that produces a sequence to iterate over the next lines.

### Item 10: Write unit tests

Summary:

* When an element is properly tested, we are not afraid to refactor it.
* Good unit tests rather save our time as we spend less time debugging and looking for bugs later.
* Unit test at least the important parts of the code.

## Chapter 2: Readability

### Item 11: Design for readability

We usually read the code to understand what is the logic or how implementation works. Programming is mostly about reading, not writing.

#### Reducing cognitive load

Take the 2 following implementations:
```kotlin
//Implementation A
if (person!=null&&person.isAdult) { 
  view.showPerson(person)
} else { 
  view.showError()
}

//Implementation B
person?.takeIf { it.isAdult } 
  ?.let(view::showPerson) 
  ?: view.showError()
```

Option A is better => When we think about readability we want to shorten this distance. We prefer less code, but also more common structures. We recognize familiar patterns when we see them often enough. We always prefer structures that we are familiar with in other disciplines.

#### Do not get extreme

```kotlin
var obj=FileInputStream("/file.gz")
  .let(::BufferedInputStream)
  .let(::ZipInputStream)
  .let(::ObjectInputStream)
  .readObject() as SomeObject
```
This code is harder to debug and harder to be understood by less experienced Kotlin developers. But we pay for something and it seems like a fair deal. The problem is when we introduce a lot of complexity for no good reason => Balancing that is an art.

#### Conventions

Conventions that need to be understood and remembered, starting with the first item which will focus on overriding operators.

### Item 12: Operator meaning should be consistent with its function name

```kotlin
print(10*6.factorial()) // 7200

print(10*!6) // 7200

operator fun Int.not() = factorial() ❌
```
The meaning of each operator in Kotlin always stays the same. Now imagine operators being used with another meaning, known only to the developers familiar with category theory. It would be way harder to understand. You would need to understand each operator separately, remember what it means in the specific context, and then keep it all in mind to connect the pieces to understand the whole statement.

![Screen Shot 2021-11-21 at 21 51 12](https://user-images.githubusercontent.com/70877098/142766825-34c4d623-17bd-4d3e-99d8-e2131c74b4f6.png)

=> Using `not` to return `factorial` is a clear breach of this convention, and should never happen.

#### Unclear cases

The biggest problem is when it is unclear if some usage fulfills conventions. For instance, what does it mean when we triple a function?

```kotlin
// Case 1:
operator fun Int.times(operation: ()->Unit) { repeat(this) { operation() } }

3 * { print("Hello") } // Prints: HelloHelloHello

// Case 2:
infix fun Int.timesRepeated(operation:()->Unit) = { repeat(this) { operation() } }
val tripledHello = 3 timesRepeated{ print("Hello") }

tripledHello() // Prints: HelloHelloHello
```

Sometimes it is better to use a top-level function instead. Repeating function 3 times is already implemented and distributed in the stdlib:

```kotlin
repeat(3) { print("Hello") } // Prints: HelloHelloHello
```

#### When is it fine to break this rule?

There is one very important case when it is fine to use operator overloading in a strange way: When we design a Domain Specific Language (DSL). To add text into an element we use `String.unaryPlus`. This is acceptable because it is clearly part of the DSL.

Summary:
* Use operator overloading conscientiously.
* The function name should always be coherent with its behavior.
* Avoid cases where operator meaning is unclear.
* If you wish to have a more operator-like syntax, then use the infix modifier or a top-level function.

### Item 13: Avoid returning or operating on `Unit?`

`getData()?.let{ view.showData(it) } ?: view.showError()` 
=> When `showData` returns `null` and `getData` returns not `null`, both `showData` and `showError` will be called. Using standard if-else is less tricky and more readable.

`if(!keyIsCorrect(key)) return` & `verifyKey(key) ?: return`
=> It is misleading and confusing and should nearly always be replaced by `Boolean`.

### Item 14: Specify the variable type when it is not clear

Type might be important information both for a developer and for the compiler. Whenever it is, do not hesitate to specify the type. It costs little and can help a lot.

### Item 15: Consider referencing receivers explicitly

We might choose a longer structure to make something explicit is when we want to highlight that a function or a property is taken from the receiver instead of being a local or top-level variable.

```kotlin
class User: Person() {
  private var beersDrunk: Int = 0

  fun drinkBeers(num: Int) { // ...
    this.beersDrunk += num // ...
  }
}
```

#### Many receivers

Using explicit receivers can be especially helpful when we are in the scope of more than one receiver when we use the `apply`, `with` or `run` functions.

```kotlin
class Node(val name:String) {
  fun makeChild(childName: String) = 
    create("$name.$childName").apply {
      print("Created ${this?.name} in "+" ${this@Node.name}")
    }
  
  fun create(name: String): Node? = Node(name) 
}

fun main() {
  val node = Node("parent") 
  node.makeChild("child") // Created parent.child in parent
}
```

This way direct receiver clarifies what receiver do we mean. This might be an important information that might not only protect us from errors but also improve readability.

#### DSL marker

For HTML DSL we use to make an HTML table, by default in every scope we can also use methods from receivers from the outer scope. We might use this fact to mess with DSL:

```html
table {
  tr {
    td { +"Column 1" }
    td { +"Column 2" }
    tr {
      td { +"Value 1" }
      td { +"Value 2" }
    }
  }
}
```
 
 To restrict such usage, we have a special meta-annotation (an annotation for annotations) that restricts implicit usage of outer receivers. This is the `DslMarker`

 ```kotlin
@DslMarker
annotation class HtmlDsl

fun table(f: TableDsl.()->Unit) { /*...*/ }

@HtmlDsl 
classTableDsl{ /*...*/ }

table {
  tr {
    td { +"Column 1" }
    td { +"Column 2" }
    tr { // COMPILATION ERROR
      td { +"Value 1" }
      td { +"Value 2" }
    }
  }
}
```

Summary:
* Do not change scope receiver.
* Explicit argument or reference is generally better.
* When need to change receiver, using explicit receivers improves readability.
* Use a label when there are many receivers to clarify.
* When need to use explicit receivers from the outer scope, can use `DslMarker` meta-annotation.

### Item 16: Properties should represent state, not behavior

You can see here that we are using the `field` identifier. This is a reference to the backing field that lets us hold data in this property. Also for a read-write property var, we can make a property by defining a getter and setter. Such properties are known as `derived properties`.

```kotlin
var name: String? = null
  get() = field?.toUpperCase() 
  set(value) {
    if(!value.isNullOrBlank()) { field = value }
  }
```

Use property delegation to extract common property patterns.

```kotlin
val db: Database by lazy { connectToDb() }
```

Here are the most typical situations when we should not use properties, and we should use functions instead:
* Operation is computationally expensive or has computational complexity higher than O(1).
* It involves business logic (how the application acts).
* It is not deterministic.
* It is a conversion, such as `Int.toDouble()`
* Getters should not change property state.

A simple rule of thumb is that a property describes and sets state, while a function describes behavior.

### Item 17: Consider naming arguments

#### When should we use named arguments?

Considering named arguments, especially for parameters:
* with default arguments,
* with the same type as other parameters,
* of functional type, if they’re not the last parameter. => like in RxJava when we subscribe to an Observable - `onNext`, `onError`

Summary:
* An exception is the last function argument when it has a special meaning.

### Item 18: Respect coding conventions

Those conventions are not optimal for all projects, but it is optimal for us as a community to have conventions that are respected in all projects:
* It is easier to switch between projects
* Code is more readable even for external developers
* It is easier to guess how code works
* It is easier to later merge code with a common repository or to move some parts of code from one project to another

Every project should look like it was written by a single person, not a group of people fighting with each other.

# Part 2: Code design

## Chapter 3: Reusability

### Item 19: Do not repeat knowledge

If you use copy-paste in your project, you are most likely doing something wrong.
DRY principle: Don’t Repeat Yourself <=> Single Source of Truth (SSOT) practice.
the WET antipattern: We Enjoy Typing, Waste Everyone’s Time or Write Everything Twice.

#### Knowledge

There are two particularly important kinds of knowledge in our programs:
1. Logic - How we expect our program to behave and what it should look like.
2. Commonalgorithms-Implementationofalgorithmstoachieve the expected behavior.
The main difference between them is that business logic changes a lot over time, while common algorithms generally do not once they are defined.

#### Everything can change

Typical reasons for the change:
* The company learns more about user needs or habits.
* Design standards change.
* We need to adjust to changes in the platform, libraries, or some tools.

Things change, and we should be prepared for that. The biggest enemy of changes is knowledge repetition. 

#### When should we allow code repetition?

The most important question to ask ourselves when we decide if two pieces of code represent similar knowledge is: Are they more likely going to change together or separately?
Single Responsibility Principle: a rule that protects us from unintended code extraction.

#### Single responsibility principle

Single Responsibility Principle is from SOLID. It states that “A class should have only one reason to change”.

The Single Responsibility Principle teaches us two things:
1. Knowledge coming from two different sources is very likely to change independently, and we should rather treat it as a different knowledge.
2. We should separate different knowledge because otherwise, it is tempting to reuse parts that should not be reused.

Summary:
* Everything changes and it is our job to prepare for that: to recognize common knowledge and extract it.
* Protect yourself from unintentional modifications by separating parts that are coming from different sources.

### Item 20: Do not repeat common algorithms

The advantages of extracting even short but repetitive algorithms are:
* Programming is faster because a single call is shorter than an algorithm (list of steps).
* They are named,so we need to know the concept by name instead of recognizing it by reading its implementation.
* We eliminate noise, so it is easier to notice something atypical.
* They can be optimized once, and we profit from this optimization everywhere we use those functions.

#### Learn the standard library

Learning the stdlib functions can be demanding, but it is worth it. Without it, developers reinvent the wheel time and time again.

#### Implementing your own utils

You don’t need to wait for more than one use. It is a well-known mathematical concept and its name should be clear for developers. Maybe another developer will need to use it later in the future and they’ll be happy to see that it is already defined.

Extension functions are a really good choice:
* Do not hold state, and so they are perfect to represent behavior. Especially if it has no side-effects.
* Compared to top-level functions, extension functions are better because they are suggested only on objects with concrete types.
* It is more intuitive to modify an extension receiver than an argument.
* Compared to methods on objects, extensions are easier to find among hints since they are suggested on objects.
* When we are calling a method, it is easy to confuse a top-level function with a method from the class or superclass, and their expected behavior is very different.

Summary:
* Do not repeat common algorithms.
* It is good to learn the standard library.
* If you need a known algorithm that is not in the stdlib, feel free to define it in your project.
* A good choice is to implement it as an extension function.

### Item 21: Use property delegation to extract common property patterns

Summary:
* Property delegates have full control over properties and have nearly all the information about their context.
* `lazy` and `observable` are just two examples from the standard library.

### Item 22: Use generics when implementing common algorithms

Functions that accept type arguments (so having type parameters) are called generic functions.

#### Generic constraints

Summary:
* Type parameters are used to have type-safe generic algorithms or generic objects.
* Type parameters can be constrained to be a subtype of a concrete type.

### Item 23: Avoid shadowing type parameters

When we shadow class type parameter with a function type parameter, such a situation is less visible and can lead to serious problems.

```kotlin
interface Tree 
class Birch: Tree 
class Spruce: Tree

// Problem: `Forest` and `addTree` type parameters are independent => Type shadowing
class Forest <T:Tree> {
  fun <T: Tree> addTree(tree: T) {
    // ...
  }
}
// => Can add both types
val forest = Forest<Birch>() 
forest.addTree(Birch()) 
forest.addTree(Spruce())
```

Solution is that addTree should use the class type parameter T:


```kotlin
// Solution
class Forest <T:Tree> {
  fun addTree(tree: T) {
    // ...
  }
}
// => Correct usage now
val forest = Forest<Birch>() 
forest.addTree(Birch()) 
forest.addTree(Spruce()) // ERROR, type mismatch
```

Summary:
* Avoid shadowing type parameters
* Be careful when you see that type parameter is shadowed.\

### Item 24: Consider variance for generic types

Generic type parameter T in the above declaration does not have any variance modifier (out or in) and by default, it is invariant. It means that there is no relation between any two types generated by this generic class. For instance, there is no relation between `Cup<Int>` and `Cup<Number>`, `Cup<Any>` or `Cup<Nothing>`.

`out` makes type parameter covariant. It means that when A is a subtype of B, and Cup is covariant (out modifier), then type `Cup<A>` is a subtype of `Cup<B>`:

```kotlin
val anys: Cup<Any> = Cup<Int>() // OK
val nothings: Cup<Nothing> = Cup<Int>() // Error
```

The opposite effect can be achieved using `in` modifier, which makes type parameter contravariant. It means that when A is a subtype of B, and Cup is contravariant, then `Cup<A>` is a supertype of `Cup<B>`

```kotlin
val anys: Cup<Any> = Cup<Int>() // Error
val nothings: Cup<Nothing> = Cup<Int>() // OK
```

Those variance modifiers are illustrated in the below diagram:

<img width="593" alt="Screen Shot 2021-11-27 at 11 00 49" src="https://user-images.githubusercontent.com/70877098/143667381-ee45d21b-8a97-4ca9-8f3e-3c3656a203e2.png">

#### The safety of variance modifiers

Covariance (out modifier) is perfectly safe with public out-positions and so they are not limited.
Contravariant (in modifier) type parameters are prohibited to use at public out-positions, it is fine when those elements are private.

#### Variance modifier positions

Variance modifiers can be used in two positions:
* The first one, the declaration-side, is more common.
* The other one is the use-site, which is a variance modifier for a particular variable.

Summary:
We have the following type modifiers:
* The default variance behavior of a type parameter is invariance. If in `Cup<T>`, type parameter T is invariant and A is a subtype of B then there is no relation between `Cup<A>` and `Cup<B>`.
* `out` modifier makes type parameter covariant. If in `Cup<T>`, type parameter T is covariant and A is a subtype of B, then Cup<A> is a subtype of `Cup<B>`. Covariant types can be used at out-positions.
* `in` makes type parameter contravariant. If in `Cup<T>`, type parameter `T` is contravariant and A is a subtype of B, then `Cup<B>` is a subtype of `Cup<A>`. Contravariant types can be used at in-positions.

* Type parameter of List and Set are covariant (out modifier).
* In function types parameter types are contravariant (in modifier) and return type is covariant (out modifier).
* We use covariance (out modifier) for types that are only returned (produced or exposed).
* We use contravariance (in modifier) for types that are only accepted.

### Item 25: Reuse between different platforms by extracting common modules

A great part of Kotlin is that it can also be compiled into JavaScript. What is even better, we can have parts that compile both to JVM bytecode and to JavaScript.

#### Mobile development

Just a few examples of what we can write in Kotlin:
* Backend in Kotlin/JVM, for instance on Spring or Ktor
* Website in Kotlin/JS, for instance in React
* Android in Kotlin/JVM, using the Android SDK
* iOS Frameworks that can be used from Objective-C or Swift, using Kotlin/Native
* Desktop applications in Kotlin/JVM, for instance in TornadoFX
* Raspberry Pi, Linux or Mac OS programs in Kotlin/Native

## Chapter 4: Abstraction design

Abstraction is a process or result of generalization, removal of properties, or distancing of ideas from objects. 
Abstraction means a form of simplification used to hide complexity. A fundamental example in programming is the interface. It is an abstraction of a class because it expresses only a subset of traits. Concretely, it is a set of methods and properties.

In programming, we use abstractions mainly to:
* Hide complexity
* Organize our code
* Give creators the freedom to change

### Item 26: Each function should be written in terms of a single level of abstraction

From a programmer’s perspective, the lowest abstraction layer of a computer is hardware.
The next interesting layer is a processor control commands. For readability, they are expressed in a very simple language that is one-to-one translated into those commands. This language is called Assembly.
To simplify programming, engineers introduced a compiler: a program that translates one language into another (generally a lower-level one).
They were in turn used to write compilers for better languages.

The big advantage of having well-separated layers is that when one operates on a specific layer, they can rely on lower levels working as expected, removing the need to fully understand the details.

<img width="546" alt="Screen Shot 2021-11-28 at 15 56 51" src="https://user-images.githubusercontent.com/70877098/143737073-190d1ed1-2221-479b-9bec-e515636550c9.png">

#### Single Level of Abstraction principle

Each function should be written in terms of a single level of abstraction.

```kotlin
class CoffeeMachine {

  // A complex function
  fun makeCoffee() {
    boilWater()
    brewCoffee()
    pourCoffee()
    pourMilk()
  }

  // Can clearly see what the general flow and steps of the complex function by extracting high-level steps as separate functions.
  private fun boilWater() { // ... }
  private fun brewCoffee() { // ... }
  private fun pourCoffee() { // ... }
  private fun pourMilk() { // ... }
}
```

This is a general rule - functions should be small and have a minimal number of responsibilities.
Additional bonus is that functions extracted this way are easier to reuse and test.

#### Abstraction levels in program architecture

The notion of layers of abstractions is also applicable to higher levels than functions. We separate abstraction to hide details of a subsystem, and it is important for when we design modular systems.

Summary:

* Making separate abstraction layers help us organize knowledge and hide details of a subsystem.
* Separating abstractions can be done in many ways, like functions, classes, modules.
* Smaller abstractions operating on a single layer are easier to understand.

### Item 27: Use abstraction to protect code against changes

*Walking on water and developing software from a specification are easy if both are frozen.*

Different kinds of abstractions give us freedom by protecting us from a variety of changes. For example, when you extract a sorting algorithm into a function, you can later optimize its performance without changing the way it is used.

#### Constant

Moving the values into constant properties not only assigns the value a meaningful name, but also helps us better manage when this constant needs to be changed.

```kotlin
const val MIN_PASSWORD_LENGTH = 7

fun isPasswordValid(text: String): Boolean {
  if(text.length < MIN_PASSWORD_LENGTH) return false 
  //...
}
```

With the above code, it is easier to modify the minimum password size. We don’t need to understand validation logic, but instead, we can just change this constant.

#### Function

We can extract a common algorithm into a simple extension function. This helps us remove the need to remember how to perform the logic every time.
A meaningful name is very important. A function represents an abstraction, and the signature of this function informs us what abstraction this is.

#### Class

The key reason why classes are more powerful than functions is that they can hold a state and expose many functions.
Additionally, we can mock the class to test the functionality of other classes that depend on the specified class.
When a class is final, we know what exact implementation is under its type. We have a bit more freedom with open classes because one could serve a subclass instead.

#### Interface

Reading the Kotlin standard library, you might notice that nearly everything is represented as an interface:
* `listOf` function returns `List`, which is an interface.
* Collection processing functions are extension functions on `Iterable` or `Collection`, and return `List`, `Map`, etc. Those are all interfaces.
* Property delegates are hidden behind `ReadOnlyProperty` or `ReadWriteProperty` which are also interfaces.
* Function `lazy` declares interface `Lazy` as its return type as well.

Library creators are sure that users do not use these classes directly, so they can change their implementations without any worries, as long as the interfaces stay the same. This way we reduce coupling.
Another benefit is that interface faking for testing is simpler than class mocking, and it does not need any mocking library.
Finally, the declaration is more decoupled from usage, and so we have more freedom in changing actual classes.

#### Next ID

It is clear that more abstractions give us more freedom, but also make definitions and usage harder to define and to understand.

```kotlin
data classId(private val id:Int)
private var nextId: Int = 0
fun getNextId(): Id = Id(nextId++)
```

#### Problems with abstraction

Adding new abstractions requires readers of the code to learn or already be familiar with the specific concept.
It becomes harder to understand the consequences of our actions when we use too many abstractions.

#### Where is the balance?

The rule of thumb is: Every level of complexity gives us more freedom and organizes our code, but also makes it harder to understand what is really going on in our project. Here are a few suggestions:
* In bigger projects with more developers, it is much harder to change object creation and usage later, so we prefer more abstract solutions. Also, a separation between modules or parts is especially useful then.
* We care less about how hard creation is when we use a dependency injection framework because we probably only need to define this creation once anyway.
* Testing or making different application variants might require us to use some abstractions.
* When your project is small and experimental, you can enjoy your freedom to directly make changes without the necessity of dealing with abstractions. Although when it gets serious, change it as soon as possible.

Summary:
* Abstractions are to eliminate redundancy, help organize and change our code easier.
* Using abstractions are something we need to learn and understand.
* Understand both the importance and risk of using abstractions, and we need to search for a balance in every project.

### Item 28: Specify API stability

We must prefer stable and possibly standard Application Programming Interfaces (API). The main reasons are:
* When the API changes and developers get the update, they will need to manually update their code.
* Users need to learn a new API and update knowledge that changed.

The simplest way is that creators should specify in the documentation to make it clear if an API or some of its parts are unstable.
When you want to allow some users to use instable API, you can use the `Experimental` meta-annotation to warn them.

```kotlin
@Experimental(level = Experimental.Level.WARNING)
annotation class ExperimentalNewApi

@ExperimentalNewApi
suspend fun getUsers(): List<User> { //... }
```

When we need to change something that is part of a stable API, to help users deal with this transition, we start with annotating this element with the `Deprecated` annotation. Also, when there is a direct alternative, specify it using `ReplaceWith`:

```kotlin
@Deprecated("Use suspending getUsers instead") 
ReplaceWith("getUsers()"))
fun getUsers(callback: (List<User>) -> Unit) { //... }
```

Then we need to give users time to adjust.

Summary
* Correct communication between module or library creators and their users is important.
* Can achieve that by using version names, documentation, and annotations.
* Each change in a stable API needs to follow a long process of deprecation.

### Item 29: Consider wrapping external API

We often wrap potentially unstable external library APIs to control them internally.

### Item 30: Minimize elements visibility

It is easier to learn and maintain a smaller interface.
When we want to make changes, it is way easier to expose something new, rather than to hide an existing element.
A class cannot be responsible for its own state when properties that represent this state can be changed from the outside.
It is easier to track how class changes when they have more restricted visibility.

#### Using visibility modifiers

For class members, we have 4 visibility modifiers:
* public (default) - visible everywhere.
* private - visible inside this class only.
* protected - visible inside this class and in subclasses.
* internal - visible inside this module.

One big limitation is that when we inherit an API, we cannot restrict the visibility of a member by overriding it.

Summary
The rule of thumb is that: Elements visibility should be as restrictive as possible.

### Item 31: Define contract with documentation

The general problem is that when the behavior is not documented and the element name is not clear, developers will depend on current implementation instead of on the abstraction we intended to create.

#### Contract

When a contract is well specified, creators do not need to worry about how the class is used, and users do not need to worry about how something is implemented under the hood
Both users and creators depend on abstractions defined in the contract, and so they can work independently.
Without users knowing what they can and cannot do, they’ll depend on implementation details instead. A creator without knowing what users depend on would be either blocked or they would risk breaking users implementations.

#### Defining a contract

There are various ways:
* Names - when a name is connected to some more general concept, we expect this element to be consistent with this concept.
* Comments and documentation - the most powerful way as it can describe everything.
* Types - Each type specifies a set of often well-defined methods.

#### Do we need comments?

To answer this question, we often do not need comments. For instance, many functions are self-explanatory and they don’t need any special description. In the end, we should write and organize our code in a way that the functions or parameters names are clear enough to explain what they mean already.

There are occasions that comments are needed. For example, to automatically generate documentation, which generally is treated as a source of truth in projects. Another case can be defining a contract for a function that contains points to sample uses, which are also useful when we are learning how to use a parameter of that function.

#### KDoc format

When we document functions using comments, the official format in which we present that comment is called KDoc. All KDoc comments start with `/**` and end with `*/`

The structure of this KDoc comment is the following:
* The first paragraph of the documentation text is the summary description of the element.
* The second part is the detailed description.
* Every next line begins with a tag. Those tags are used to reference an element to describe it.

```kotlin
/**
* Immutable tree data structure.
*
* Class represents immutable tree having from 1 to
* infinitive number of elements. In the tree we hold 6 
* elements on each node and nodes can have left and 
* right subtrees...
*
* @param T the type of elements this tree holds.
* @property value the value kept in this node of the tree.
* @property left the left subtree.
* @property right the right subtree.
*/
class Tree<T>(
  val value: T,
  val left: Tree<T>? = null,
  val right: Tree<T>? = null
){
  operator fun plus(element: T): Tree { ... }
}
```

#### Type system and expectations

Liskov substitution principle: It is generally translated to “if S is a subtype of T, then objects of type T may be replaced with objects of type S without altering any of the desirable properties of the program”. => children should always satisfy parents’ contracts.

#### Leaking implementation

For instance, calling a function using `reflection` works, but it is significantly slower than a normal function call. 
We protect it by encapsulation, which can be described as “You can do what I allow, and nothing more”.

 Summary:
* When we define an element, especially parts of external API, we should define a contract.
* The contract specifies what the expectations are on those elements and can also describe how an element should be used.
* A contract gives users confidence about how elements behave now and will behave in the future.
* Gives creators the freedom to change what is not specified in the contract.

### Item 32: Respect abstraction contracts

Just because you can do something, doesn’t mean that it is fine to do it.
When you break the contract, it is your problem when implementation changes and your code stops working.

#### Contracts are inherited

Remember that our object should respect the contracts when we inherit them from classes or extend interfaces from another library.

Summary:
* If you want your programs to be stable, respect contracts.
* If you are forced to break them, document this fact well.

## Chapter 5: Object creation

### Item 33: Consider factory functions instead of constructors

Using factory functions instead of a constructor has many advantages, including:
* Unlike constructors,functions have names. Names explain how an object is created and what the arguments are.
* Unlike constructors, functions can return an object of any subtype of their return type. This can be used to provide a better object for different cases.
* Unlike constructors, functions are not required to create a new object each time they’re invoked. It can be helpful when include a caching mechanism to optimize object creation or returns `null` if the object cannot be created.
* Factory functions can provide objects that might not yet exist.
* When we define a factory function outside of an object, we can control its visibility.
* Factory functions can be inline and so their type parameters can be reified.
* Factory functions can construct objects which might otherwise be complicated to construct.
* A constructor needs to immediately call a constructor of a superclass or a primary constructor.

There is a limitation on factory functions usage: it cannot be used in subclass construction.
Factory functions are not a competition to the primary constructor, instead they are mainly a competition to secondary constructors and themselves as there are variety of different kinds of factory functions.

#### Companion Object Factory Function

The most popular way to define a factory function is to define it in a companion object.

A short word like `of` is enough to understand what the arguments mean. Here are some common names with their descriptions:
* `from` - A type-conversion function that takes a single parameter and returns a corresponding instance of the same type 
`val date: Date = Date.from(instant)`
* `of` - An aggregation function that takes multiple parameters and returns an instance of the same type that incorporates them
`val faceCards: Set<Rank> = EnumSet.of(JACK, QUEEN, KING)`
* `valueOf` - A more verbose alternative to from and of
`val prime: BigInteger = BigInteger.valueOf(Integer.MAX_- VALUE)`
* `instance` or `getInstance` - Used in singletons to get the only instance
`val luke: StackWalker = StackWalker.getInstance(options)`
* `createInstance` or `newInstance` - Like `getInstance`, but this function guarantees that each call returns a new instance.
`val newArray = Array.newInstance(classObject, arrayLen)`
* `getType` - Like `getInstance`, but used if the factory function is in a different class.
`val fs: FileStore = Files.getFileStore(path)`
* `newType` - Like `newInstance`, but used if the factory function is in a different class.
`val br: BufferedReader = Files.newBufferedReader(path)`

#### Extension factory functions

When we either cannot modify this companion object or we just want to specify a new function in a separate file, we can define an extension function on its companion object:

```kotlin
interface Tool {
  companion object { /*...*/ }
}

fun Tool.Companion.createBigTool(/*...*/): BigTool { //... }
```

#### Top-level functions

Object creation using top-level functions is a perfect choice for small and commonly created objects. => `List` or `Map` because `listOf(1,2,3)` is simpler and more readable than `List.of(1,2,3)`.

#### Fake constructors

Two main reasons why developers choose fake constructors over the real ones are:
* To have “constructor” for an interface 
* To have reified type arguments

```kotlin
public inline fun<T>List( 
  size: Int,
  init: (index: Int) -> T 
):List<T> = MutableList(size, init)

List(4){ "User$it" } // [User0,User1,User2,User3]
```

Implementing `invoke` in a companion object to make a fake constructor is very rarely used not recommended.

#### Methods on a factory class

Factory classes can have properties and those properties can be used to optimize object creation. For instance use caching, or speed up object creation by duplicating previously created objects.

Summary:
* Preferably be used with caution: `Fake Constructors`, `Top-Level Factory Method`, and `Extension Factory Function`.
* The most universal way to define a factory function is by using a `Companion Object`.

### Item 34: Consider a primary constructor with named optional arguments

It is very common that we need to pass arguments that determine the object’s initial state.

#### Telescoping constructor pattern

The telescoping constructor pattern is nothing more than a set of constructors for different possible sets of arguments.

Default arguments are more powerful than the telescoping constructor because:
* We can set any subset of parameters with default arguments we want.
* We can provide arguments in any order.
* We can explicitly name arguments to make it clear what each value means.

#### Builder pattern

Named parameters and default arguments are not allowed in Java. This is why Java developers mainly use the builder pattern.

```kotlin
class Builder(private val size: String) {
  private var cheese: Int = 0
  private var olives: Int = 0
  private var bacon: Int = 0
){
  fun setCheese(value: Int): Builder = apply { cheese = value }
  fun setOlives(value: Int): Builder = apply { olives = value }
  fun setBacon(value: Int): Builder = apply { bacon = value }
  fun build() = Pizza(size, cheese, olives, bacon) 
}

// Builder usage
val villagePizza = Pizza.Builder("L")
    .setCheese(1)
    .setOlives(2)
    .setBacon(3)
    .build()
```

Advantages of named parameters over the builder:
* shorter
* cleaner
* simpler usage
* no problems with concurrence -> function parameters are always immutable in Kotlin, while properties in most builders are mutable. -> harder to implement a thread-safe build function for a builder.

The builder pattern is rarely the best option in Kotlin. It is sometimes chosen:
* to make code consistent with libraries written in other lan- guages that used builder pattern.
* when we design API to be easily used in other languages that do not support default arguments or DSLs.

Summary:
* Creating objects using a primary constructor is the most appropriate approach
* Telescoping constructor patterns should be treated as obsolete
* The builder pattern is very rarely reasonable

### Item 35: Consider defining a DSL for complex object creation

Summary:
* A DSL is a special language inside of a language and they should be only used when they offer real value, i.e. for the creation of a really complex object, or possibly for complex object hierarchies.

## Chapter 6: Class design

### Item 36: Prefer composition over inheritance

When all we need is a simple code extraction or reuse, inheritance should be used with caution, and we should instead prefer a lighter alternative: class composition.

#### Simple behavior reuse

With inheritance, it has important downsides we should be aware of:
* We can only extend one class that extracting functionalities using inheritance often leads to huge BaseXXX classes that accumulate many functionalities or too deep and complex hierarchies of types.
* When we extend, we take everything from a class.
* Using superclass functionality is much less explicit -> it is a bad sign when a developer reads a method and needs to jump into superclasses many times to understand how the method works.

By composition, we mean holding an object as a property (we compose it) and reusing its functionalities.

```kotlin
class Progress {
  fun showProgress() { /* show progress */ } 
  fun hideProgress() { /* hide progress */ }
}

class ProfileLoader {
  val progress = Progress()

  fun load() {
    progress.showProgress()
    
    // load profile
    progress.hideProgress()
  }
}
```

#### Taking the whole package

When we use inheritance, we take from superclass everything - both methods, expectations (contract) and behavior. But it is not necessary to just reuse some common parts. For such cases, the composition is better because we can choose what behavior do we need. For example:
```kotlin
abstract class Dog { // a Dog that can bark and sniff
  open fun bark() { /*...*/ }
  open fun sniff() { /*...*/ }
}
class Labrador: Dog() // Normal dog

class RobotDog: Dog() { // Robot dog can't sniff
  override fun sniff() {
    throw Error("Operation not supported") // Do you really want that?
  }
}
```

Such a solution violates interface-segregation principle - RobotDog has a method it doesn’t need. 
It also violates the Liskov Substitution Principle by breaking superclass behavior.
What if your `RobotDog` needs to be a Robot class as well because Robot can calculate (have calculate method)? `Multiple inheritance` is not supported in Kotlin.

#### Inheritance breaks encapsulation

When we extend a class, we depend not only on how it works from outside but also on how it is implemented inside. This is why we say that inheritance breaks encapsulation.

The delegation pattern is when our class implements an interface, composes an object that implements the same interface, and forwards methods defined in the interface to this composed object. Such methods are called `forwarding methods`.

#### Restricting overriding

To prevent developers from extending classes that are not designed for an inheritance, we can just keep them `final`. To let developers override them, they must be set to `open`.

Summary:
There are a few important differences between composition and inheritance:
* more secure -> do not depend on how a class is implemented, but only on its externally observable behavior.
* more flexible -> Can only extend a single class, while we can compose many. When inheriting, we take everything, while when we compose, we can choose what we need. When we change the behavior of a superclass, we change the behavior of all subclasses but when a class we composed changes, only change our behavior if it changed its contract to the outside world.
* more explicit -> When we use a method from a superclass we don’t need to reference any receiver. When we call a method on a composed object, we know where it comes from.
* more demanding -> When we add some functionalities to a superclass => often do not need to modify subclasses, but when we use composition => more often need to adjust usages.
* Inheritance gives us a strong polymorphic behavior ->  From one side, it is comfortable that a dog can be treated like an animal. On the other side, it is very constraining that it must be an animal.
Kotlin encourages composition even more by making all classes and methods final by default and by making interface delegation a first-class citizen.
The rule of thumb: we should use inheritance when there is a definite “is a” relationship.

### Item 37: Use the data modifier to represent a bundle of data

When we add the `data` modifier, it generates a few useful functions:
* toString
* equals and hashCode
* copy
* componentN (component1, component2, etc.) -> `val(id, name, pts) = player`

We need to be careful with destructuring. We need to adjust every destructuring when the order of elements in data class change. It also is easy to destructure incorrectly by confusing order. If a user destructures to variables with different names than those described in the data class, a warning will be displayed.

#### Prefer data classes instead of tuples

* Kotlin had support for tuples when it was still in the beta version but now only `Pair` and `Triple`. They stayed because they are used for local purposes: When we immediately name values, or To represent an aggregate not known in advance
* If you don’t want this class in a wider scope, you can restrict its visibility. 
* Classes are cheap in Kotlin, do not be afraid to use them.

### Item 38: Use function types instead of interfaces to pass operations and actions

Many languages use interfaces with a single method instead of a function type. Such interfaces are known as SAM’s (Single-Abstract Method).

```kotlin
interface OnClick {
  fun clicked(view: View)
}
```

However, declaring a parameter with a function type gives us much more freedom:

```kotlin
fun setOnClickListener(listener: (View) -> Unit) { //... }
```

* We can pass the parameter as a lambda expression or an anonymous function -> `setOnClickListener{/*...*/}`
* We can pass the parameter as a function reference or bounded function reference -> `setOnClickListener(::println)`
* We can pass the parameter as a objects that implement the declared function type -> `setOnClickListener(ClickListener())`
* Parameters can also be named.
* When we use lambda expressions, we can also destructure arguments.

#### When should we prefer a SAM?

There is one case when we prefer a SAM: When we design a class to be used from another language than Kotlin. Interfaces are cleaner for Java clients.

### Item 39: Prefer class hierarchies to tagged classes

Classes with a constant “mode” that specifies how the class should behave are called tagged classes as they contain a tag that specifies their mode of operation. There are many downsides to this approach:
* Additional boilerplate from handling multiple modes in a single class.
* Inconsistently used properties, as they are used for different purposes. 
* The object generally has more properties than they need as they might be required by other modes.
* It is hard to protect state consistency and correctness.
* It is often required to use a factory method since it is hard to ensure that objects are created correctly.

We have a better alternative in Kotlin: `sealed` classes that we should define multiple classes for each mode, and use the type system to allow their polymorphic use.

#### Sealed modifier

We could use `abstract` instead, but `sealed` forbids any subclasses to be defined outside of that file.

`Sealed` modifier makes it easier to add new functions to the class using extensions or to handle different variants of this class. `Abstract` classes leave space for new classes joining this hierarchy.

#### Tagged classes are not the same as state pattern

The `state` pattern is a behavioral software design pattern that allows an object to alter its behavior when its internal state changes.

The difference here is that:
* The state is a part of a bigger class with more responsibilities.
* The state changes.

Summary:
* sealed classes represent a sum type (a type collecting alternative class options).
* sealed classes cooperates with the state pattern.

### Item 40: Respect the contract of `equals`

In Kotlin, every object extends `Any`, which has a few methods with well-established contracts. These methods are:
* equals
* hashCode 
* toString

#### Equality

There are two types of equality:
* Structural equality - checked by the equals method or `==` -> checks if another object values are the same (same type)
* Referential equality - checked by the `===` operator -> checks if another object is exactly the same instance

#### Why do we need equals?

* We need its logic to differ from the default one
* We need to compare only a subset of properties
* We do not want our object to be a data class or properties we need to compare are not in the primary constructor

#### The contract of equals

* Reflexive -> x.equals(x) should return true
* Symmetric -> x.equals(y) should return true if and only if y.equals(x) returns true.
* Transitive -> if x.equals(y) returns true and y.equals(z) returns true, then x.equals(z) should return true.
* Consistent -> multiple invocations of x.equals(y) consistently return true or false, if no information used in equals comparisons on the objects is modified.
* Never equal to null -> x.equals(null) should return false.

#### Problem with equals in URL

Equality of two `java.net.URL` objects depends on a network operation as two hosts are considered equivalent if both hostnames can be resolved into the same IP addresses. The most important problems for this:
* This behavior is inconsistent.
* The network may be slow and we expect `equals` and `hashCode` to be fast.
* The defined behavior is known to be inconsistent with virtual hosting in HTTP.

#### Implementing equals

It is recommended to go against implementing equals ourselves unless we have a good reason. Instead, use default or data class equality.

### Item 41: Respect the contract of `hashCode`

#### Hash table

The problem hash table was invented to solve: we need a collection that quickly both adds and finds elements.

A collection based on an array or on linked elements is not fast enough for checking if it contains an element, because to check that we need to compare this element with all elements on this list one after another. It will be really time-consuming to compare your text one after another with those millions.

A popular solution to this problem is a hash table. All you need is a function that will assign a number to each element. A good hash function are: 
* Fast
* Ideally returns different values for unequal elements, or at least has enough variation to limit collisions to a minimum

Such a function categorizes elements into different buckets by assigning a number to each one. 
All elements equal to each other will always be placed in the same bucket. 
Those buckets are kept in a structure called hash table, which is an array with a size equal to the number of buckets.
Every time we add an element, we use our hash function to calculate where it should be placed, and we add it there.
When we search for an element, we find its bucket the same way and then we only need to check if it is equal to any element in this bucket.

#### Problem with mutability

A hash is calculated for an element only when this element is added. An element is not moved when it mutates. `LinkedHashSet` and `LinkedHashMap` key will not behave properly when an object mutates after it has been added -> We should not use mutable elements for sets or as keys for maps, or at least we should not mutate elements that are in such collections.

#### The contract of `hashCode`

* Whenever it is invoked on the same object more than once, the hashCode method must consistently return the same integer.
* If two objects are equal according to the `equals` method,then calling the hashCode method on each of the two objects must produce the same integer result.

#### Implementing hashCode

We define `hashCode` in Kotlin practically only when we define custom `equals`.
Do not have a custom `equals` method -> do not define a custom `hashCode`.
If you implemented typical `equals` that checks equality of significant properties, then a typical `hashCode` should be calculated using the hash codes of those properties.

### Item 42: Respect the contract of `compareTo`

When an object implements this interface or when it has an operator method named `compareTo`, it means that this object has a natural order.

* Antisymmetric -> if a >= b and b >= a then a == b.
* Transitive -> if a >= b and b >= c then a >= c. Similarly when a > b and b > c then a > c.
* Connex -> either a >= b, or b >= a.

#### Do we need a compareTo?

In Kotlin we rarely implement `compareTo` ourselves.
Compare two strings using a comparision sign seems highly unintuitive. -> `print("Kotlin" > "Java") //true`

#### Implementing compareTo

If all you need is to compare two values, you can use the `compareValues` function
If you need to use more values, or if you need to compare them using selectors, use `compareValuesBy`

### Item 43: Consider extracting non-essential parts of your API into extensions

When we define final methods in a class, we need to make a decision if we want to define them as members, or if we want to define them as extension functions.

They both have their pros and cons, and one way does not dominate over another:
* The biggest difference between members and extensions in terms of use is that extensions need to be imported separately as they can be located in a different package.
* We can have many extensions with the same name on the same type. On the other hand, it would be dangerous to have two extensions with the same name, but having different behavior.
* Another significant difference is that extensions are not virtual, meaning that they cannot be redefined in derived classes. Therefore we should not use extensions for elements that are designed for inheritance.
* Extension functions under the hood are compiled into normal functions -> we define extensions on types, not on classes which gives us more freedom.
* The last important difference is that extensions are not listed as members in the class reference. -> they are not considered by annotation processors and we process a class using annotation processing -> cannot extract elements that should be processed into extension functions. On the other hand, if we extract non-essential elements into extensions, we don’t need to worry about them being seen by those processors.

Summary:
* Extensions need to be imported
* Extensions are not virtual
* Member has a higher priority
* Extensions are on a type, not on a class
* Extensions are not listed in the class reference
* Extensions give us more freedom and flexibility
* Extensions do not support inheritance, annotation processing, and it might be confusing since they are not present in the class.
* Extensions are for extracting non-essential parts of your API

### Item 44: Avoid member extensions

When we define an extension function to some class, it is not added to this class as a member. An extension function is just a different kind of function that we call on the first argument that is there, called a receiver.

```kotlin
fun String.isPhoneNumber(): Boolean = length == 7 && all { it.isDigit() }

// Under the hood
fun isPhoneNumber(`$this`:String): Boolean = `$this`.length == 7 && `$this`.all { it.isDigit() }
```

Do not define extension as members just to restrict visibility -> One big reason is that it does not really restrict visibility. It only makes it more complicated to use.

```kotlin
class PhoneBookIncorrect { 
  fun String.isPhoneNumber() = length == 7 && all { it.isDigit() }
}

PhoneBookIncorrect().apply { "1234567890".test() } // Bad practice, do not do this
```

You should restrict the extension visibility using a visibility modifier and not by making it a member.

=> If there is a good reason to use a member extension, it is fine. Just be aware of the downsides and generally try to avoid it.

# Part 3: Efficiency

## Chapter 7: Make it cheap

Memory is cheap and developers are expensive. Though if your application is running on millions of devices, it consumes a lot of energy, and some optimization of battery use might save enough energy to power a small city.

Company is paying lots of money for servers and their maintenance, and some optimization might make it significantly cheaper.

Application works well for a small number of requests but does not scale well and on the day of the trial, it shuts down.

Efficiency is important in the long term, but optimization is not easy. Premature optimization often does more harm than good.

### Item 45: Avoid unnecessary object creation

Avoiding unnecessary object creation can be an important optimization. It can be done on many levels. For instance, in JVM it is guaranteed that a string or boxed primitives object will be reused by any other code running in the same virtual machine

```kotlin
val str1 = "Loremipsumdolorsitamet"
val str2 = "Loremipsumdolorsitamet"
print(str1==str2) //true
print(str1===str2) //true
```

#### Is object creation expensive?

* Objects take additional space. -> object has a 12-byte header, padded to a multiple of 8 bytes, so the minimum object size is 16 bytes.
* Access requires an additional function call when elements are encapsulated. -> function use is fast but can addup on a large pool of objects. 
* Objects need to be created. -> An object needs to be created, allocated in the memory, a reference needs to be created, etc.

#### Object declaration

A very simple way to reuse an object instead of creating it every time is using object declaration (singleton).

#### Factory function with a cache

Factory functions can have cache. The simplest case is when a factory function always returns the same object. For instance, `emptyList` from stdlib -> `fun<T>emptyList():List<T>=EmptyList` 

Caching can also be done for parameterized factory methods. In such a case, we might keep our objects in a map.

Memoization: Caching for all pure functions.

A significant drawback with cache: we are reserving and using more memory since the Map needs to be stored somewhere. 

One thing that helps is using a soft reference that can be removed by the GC when memory is needed. 
-> `private val FIB_CACHE: MutableMap<Int,BigInteger> by SoftReferenceDelegate { mutableMapOf<Int, BigInteger>() }`

- Weak references: do not prevent GarbageCollector from cleaning up the value. So once no other reference (variable) is using it, the value will be cleaned.
- Soft references: are not guaranteeing that the value won’t be cleaned up by the GC either, but in most JVM implementations, this value won’t be cleaned unless memory is needed -> perfect for a cache.

Caching is always a tradeoff: performance for memory. Remember this, and use caches wisely.

#### Heavy object lifting

Extracting a value calculation to an outer scope to not calculate it is an important practice.

```kotlin
private val IS_VALID_EMAIL_REGEX = "\\A(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\z".toRegex()

fun String.isValidIpAddress(): Boolean = matches(IS_VALID_EMAIL_REGEX)
```

#### Lazy initialization

Often when we need to create a heavy class, it is better to do that lazily. -> Each object will then be initialized just before its first usage. The cost of those objects creation will be spread instead of accumulated.

#### Using primitives

Some cases where a wrapped class needs to be used:
* When we operate on a nullable type (primitives cannot be null)
* When we use the type as a generic

Using primitives makes sense only when operations on a number are repeated many times.
This optimization only for performance critical parts of our code and in libraries as forced changes might lead to less readable code.

Summary:
* Heavy object lifting out of a loop or function is generally a good idea. -> name this object so we make our function easier to read
* Avoid premature optimization unless we have such guidelines in our project.

### Item 46: Use inline modifier for functions with parameters of functional types

During compilation, `inline` modifier make all uses of this function are replaced with its body. Also, all calls of function arguments inside repeat are replaced with those functions bodies.

```kotlin
inline fun repeat(times: Int, action: (Int) -> Unit) {
  for (index in 0 until times) { action(index) }
}

repeat(10) { print(it) } // call inline function

for (index in 0 until 10) { print(index) } // turns into this during compilation
```

In a normal function, execution jumps into this function body, invokes all statements, then jumps back to the place where the function was invoked.

#### A type argument can be reified

By making a function inline, Function calls are replaced with its body, so type parameters uses can be replaced with type arguments, by using the reified modifier:

```kotlin
fun <T> printTypeName() { print(T::class.simpleName) } // ERROR 

inline fun <reified T> printTypeName() { print(T::class.simpleName) } // OK
```

#### Functions with functional parameters are faster when they are inlined

All functions are slightly faster when they are inlined because there is no need to jump with execution and to track the back-stack.

This difference is most likely insignificant when a function does not have any functional parameter though.

⚠️ Function types are just interfaces -> `(Int, Int) -> Int` compiles to `Function2<Int, Int, Int>` 

Wrapping the body of a function into an object will slow down the code:
```kotlin
@Benchmark fun nothingInline(blackhole: Blackhole) {
  repeat(100_000_000) { blackhole.consume(it) } // on average 189 ms
}

@Benchmark fun nothingNoninline(blackhole: Blackhole) {
  noinlineRepeat(100_000_000) { blackhole.consume(it) } // on average 447 ms
}
```
-> This difference comes from the fact that in the first function we only iterate over numbers and call an empty function. In the second function, we call a method that iterates over numbers and calls an object, and this object calls an empty function.

A local variable cannot be really used directly in non-inlines lambda.
```kotlin
@Benchmark fun nothingInline(blackhole: Blackhole) {
  val l = 0L
  repeat(100_000_000) { l += it } // on average 30 ms
  blackhole.consume(l)
}

@Benchmark fun nothingNoninline(blackhole: Blackhole) {
  val l = 0L
  noinlineRepeat(100_000_000) { l += it } // on average 274 ms
  blackhole.consume(l)
}
```
-> This comes from the accumulated effects of the facts that the function is compiled to be an object, and the local variable needs to be wrapped.

#### Non-local return is allowed

Functions can look and behave more like control structures:
```kotlin
fun getSomeMoney(): Money? { 
  repeat(100) {
    val money = searchForMoney() 
    if(money != null) return money
  }
  return null 
}
```

#### Costs of inline modifier

Inline functions cannot be recursive. Otherwise, they would replace their calls infinitely.

Inline functions cannot use elements with more restrictive visibility. -> they cannot be used to hide implementation, and rarely used in classes.

They make our code grow.

#### Crossinline and noinline

`crossinline` - it means that the function should be inlined but non-local return is not allowed.
`noinline` - it means that this argument should not be inlined at all.

It is good to know them but we can live without remembering them as IntelliJ IDEA suggests them when they are needed.

Summary:
The main cases where we use inline functions are:
* Very often used functions, like print.
* Functions that need to have a `reified` type passed as a type argument, like `filterIsInstance`.
* When we define top-level functions with parameters of functional types.
* Rarely use inline functions to define an API.
* Remember that code growth accumulates.

### Item 47: Consider using inline classes

Such a class will be replaced with the value it holds whenever possible:
```kotlin
inline class Name(private val value: String) { //... }

val name: Name = Name("Marcin") // declare inline class

val name: String = "Marcin" // turns into this during compilation
```

#### Indicate unit of measure

What is this time? Might be time in milliseconds, seconds, minutes -> A great way to solve this problem is to introduce stricter types that will protect us from misusing more generic types, and to make them efficient we can use inline classes:

```kotlin
inline val Int.min
get() = Minutes(this)
inline val Int.ms
get() = Millis(this)
val timeMin: Minutes = 10.min
```

#### Protect us from type misuse

Let’s say that you have a student grade in a system. It will probably need to reference the id of a student, teacher, school. The problem is that it is really easy to later misuse all those ids, and the typing system does not protect us because they are all of type `Int` -> Wrap all those integers into separate inline classes:

```kotlin
inline class StudentId(val studentId: Int)
inline class TeacherId(val teacherId: Int)
inline class SchoolId(val studentId: Int)
```

#### Inline classes and interfaces

When we present inline classes through an interface, such classes are not inlined.

#### Typealias

Kotlin typealias lets us create another name for a type -> is a useful capability used especially when we deal with long and repeatable types.

Typealiases do not protect us in any way from type misuse -> to indicate a unit of measure, use a parameter name or classes. A name is cheaper, but classes give better safety. When we use inline classes, we take the best from both options - it is both cheap and safe.

Summary:

* Inline classes let us wrap a type without performance overhead.
* If you use a type with unclear meaning, especially a type that might have different units of measure, consider wrapping it with inline classes.

### Item 48: Eliminate obsolete object references

The single most important rule is that we should not keep a reference to an object that is not useful anymore. 

Holding a reference to an activity in a companion object does not let Garbage Collector release it as long as our application is running.

Manage dependencies properly instead of storing them statically.

when we hold state, we should have memory management in our minds.

Some objects can be referenced using weak reference. For instance a Dialog on a screen. As long as it is displayed, it won’t be Garbage Collected anyway. Once it vanishes we do not need to reference it anyway. It is a perfect candidate for an object being referenced using a weak reference.

The most important way to avoid cluttering our memory is having variables defined in a local scope.

## Chapter 8: Efficient collection processing

### Item 49: Prefer Sequence for big collections with more than one processing step

`Sequences` are lazy, so intermediate functions for Sequence processing don’t do any calculations. All these computations are evaluated during a terminal operation like `toList` or `count`.

<img width="622" alt="Screen Shot 2021-11-29 at 00 36 31" src="https://user-images.githubusercontent.com/70877098/143779310-206efa61-5579-4d07-9263-acb9bafbde6a.png">

`Iterable` processing, on the other hand, returns a collection like List on every step.

#### Order is important

In sequence processing, we take the first element and apply all the operations, then we take the next element, and so on -> element-by-element or lazy order.
In iterable processing, we take the first operation and we apply it to the whole collection, then move to the next operation, etc.. -> step-by-step or eager order.

<img width="633" alt="Screen Shot 2021-11-29 at 00 43 06" src="https://user-images.githubusercontent.com/70877098/143779500-66d09429-806d-43be-87ab-86836b80373c.png">

-> Element-by-element order is more natural.

#### Sequences do the minimal number of operations

When we have some intermediate processing steps and our terminal operation does not necessarily need to iterate over all elements, using a sequence will most likely be better for the performance of your processing.

#### Sequences can be infinite

Sequences do processing on-demand, we can have infinite sequences. A typical way to create an infinite sequence is using sequence generators like `generateSequence` or `sequence`:

```kotlin
generateSequence(1) { it+1 }
  .map { it * 2 }
  .take(10)
  .forEach { print("$it,") } // Prints:2,4,6,8,10,12,14,16,18,20,
```

Need to limit them using an operation like `take`, or we need to use a terminal operation that will not need all elements, like `first`, `find`, `any`, `all`, `none` or `indexOf`.

#### Sequences do not create collections at every processing step

Let’s start from an extreme and yet common case: file reading. Files can weigh gigabytes. Allocating all the data in a collection at every processing step would be a huge waste of memory. This is a problem especially when we are dealing with big or heavy collections. -> use sequences to process files.

Prefer to use Sequence for big collections with more than one processing step.

#### When aren’t sequences faster?

`sorted` is an example from Kotlin that it uses optimal implementation: It accumulates the `Sequence` into `List`.


#### What about Java stream?

Three big differences between Java streams and Kotlin sequences are the following:
* Kotlin sequences have many more processing functions.
* Java stream processing can be started in parallel mode using a parallel function. This can give us a huge performance improvement in contexts when we have a machine with multile cores that are often unused.
* Kotlin sequences can be used in common modules, Kotlin/JVM, Kotlin/JS, and Kotlin/Native modules. Java streams only in Kotlin/JVM, and only when the JVM version is at least 8.

-> Use Java streams rarely, only for computationally heavy processing where you can profit from the parallel mode.

#### Kotlin Sequence debugging

Sequences also required plugin named “Kotlin Sequence Debugger”, now this functionality is integrated into Kotlin plugin.

Summary:
* Sequences are lazy, and thus are better to process heavy objects or for bigger collections with more than one processing step.
* Sequences are also supported by Kotlin Sequence Debugger that can help us by visualizing how elements are processed.

### Item 50: Limit the number of operations

We can limit the number of collection processing steps by using operations that are composites. For example, instead of mapping and then filtering out nulls, we can just do `mapNotNull`.

Alternative composite operations list:

<img width="654" alt="Screen Shot 2021-11-29 at 01 00 07" src="https://user-images.githubusercontent.com/70877098/143780093-2e2cceb2-c55b-4de1-85db-223a6ad0e238.png">

Summary:
* Using more suitable collection processing functions.

### Item 51: Consider Arrays with primitives for performance-critical processing

Primitives are:
* Lighter, as every object adds additional weight.
* Faster, as accessing the value through accessors is an additional cost.

In the performance-critical parts of our code we should instead consider using arrays with primitives, like `IntArray` or `LongArray`, as they are lighter in terms of memory and their processing is more efficient.

How much lighter arrays with primitives are? -> Let’s say that in Kotlin/JVM we need to hold 1 000 000 integers, and we can either choose to keep them in `IntArray` or in `List<Int>`:
* the `IntArray` allocates 4 000 016 bytes
* `List<Int>` allocates 20 000 040 bytes
-> It is 5 times more

Summary:
* In a typical case, List or Set should be preferred over Array.
* Hold big collections of primitives, using Array might significantly improve your performance and memory use, such as writing games or advanced graphic processing.

### Item 52: Consider using mutable collections

The biggest advantage of using mutable collections instead of immutable is that they are faster in terms of performance.

When we add an element to an immutable collection, we need to create a new collection and add all elements to it.

When using mutable collections, especially if we need to add elements, is a performance optimization.

The advantages of using immutable collections for safety -> those arguments rarely apply to local variables where synchronization or encapsulation is rarely needed.

For local processing, it generally makes more sense to use mutable collections.

Summary:
* Adding to mutable collections is generally faster
* Immutable collections give us more control over how they are changed

# Dictionary

Can define anonymous functions using function literals:
```kotlin
val double = fun(i: Int) = i*2 // Anonymous function
val triple = {i: Int -> i*3 } // Lambda expression - a shorter notation for an anonymous function
```

The `parameter` is a variable defined in a function declaration. The `argument` is the actual value of this variable that gets passed to the function.
