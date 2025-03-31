## Modules Overview
- Modules attach specific behavior to classes and organize code using composition over inheritance.
- Gems like Sidekiq use modules for easier integration.

```ruby
module Logging
  def log(level, message)
    File.open("log.txt", "a") do |f|
      f.write "#{level}: #{message}"
    end
  end
end

class Service
  include Logging

  def do_something
    begin
      # do something
    rescue StandardError => e
      log :error, e.message
    end
  end
end
```

## Ancestors Chain
- Ruby classes have an **ancestors chain** listing inherited classes and included modules.
- Ruby searches this chain to resolve methods at runtime.
- If no method is found, `method_missing` of `BasicObject` is called.

```ruby
> String.ancestors
=> [String, Comparable, Object, PP::ObjectMixin, Kernel, BasicObject]
```

## Include
- `include` inserts a module into the ancestors chain just after the superclass.
- Methods from the module become **instance methods** of the class.
- Last included module takes precedence in conflicts.

```ruby
module Logging
  def log(message)
    # log in a file
  end
end

module Debug
  def log(message)
    # debug output
  end
end

class Service
  include Logging
  include Debug
end

p Service.ancestors # [Service, Debug, Logging, Object, ...]
```

## Extend
- `extend` adds module methods as **class methods** instead of instance methods.
- The module is inserted into the **singleton class** of the target class.
- `include` + `extend` combo can define both instance and class methods using `included` hook.

```ruby
module Logging
  module ClassMethods
    def logging_enabled?
      true
    end
  end

  def self.included(base)
    base.extend(ClassMethods)
  end

  def log(level, message)
    # ...
  end
end
```

## Prepend
- `prepend` inserts the module **before the class** itself in the ancestors chain.
- This allows the module to override class methods and call `super` to execute the original method.
- Useful for decorating existing classes with additional behavior.

```ruby
module ServiceDebugger
  def run(args)
    puts "Service run start: #{args.inspect}"
    result = super
    puts "Service run finished: #{result}"
  end
end

class Service
  prepend ServiceDebugger

  # perform some real work
  def run(args)
    args.each do |arg|
      sleep 1
    end
    {result: "ok"}
  end
end

> Service.ancestors
=> [ServiceDebugger, Service, Object, ...]
```
