require 'celluloid/autostart'

class Counter
  attr_reader :counter
  
  def initialize
    @counter = 0
  end

  # Not threadsafe!
  def increment
    @counter += 1
  end
end

c = Counter.new
10.times.map { Thread.new { 1000.times { c.increment }}  }.map(&:join)
puts c.counter

class CounterActor
  include Celluloid

  attr_reader :counter

  def initialize
    @counter = 0
  end

  # Threadsafe
  def increment
    @counter += 1
  end
end

ca = CounterActor.new
10.times.map { Thread.new { 1000.times { ca.increment }}  }.map(&:join)
puts ca.counter
