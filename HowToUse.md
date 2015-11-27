rudebug is started by typing `rudebug` into a console.

# With ruby-debug #

Here's a sample application you can use for testing:

```
begin
  require 'rubygems'
rescue LoadError
  # RubyGems not installed
end

require 'ruby-debug'
Debugger.wait_connection = true
Debugger.start_remote

class Person
  def initialize(name, age)
    @name = name
    @age = age
    debugger
    puts "Created #{@name}"
  end
  
  def greet(target = "World")
    debugger
    puts "#{@name} (#{@age}): Hello #{target}!"
  end
end

{
  "Heinrich Heinrichson" => 30,
  "David Davidson" => 40,
  "Kurt Kurtson" => 50
}.each do |(name, age)|
  person = Person.new(name, age)
  person.greet
end
```

After running that code, start rudebug and select `localhost:8989` from the connection dialog's server dropdown, then click connect. (Enter the actual server address instead of localhost if you're not going to run the script and debugger on the same host.)

# With ruby-breakpoint #

Support for ruby-breakpoint is in rudebug, but should not be used as ruby-breakpoint is no longer being maintained.