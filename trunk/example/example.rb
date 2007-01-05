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
