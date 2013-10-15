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

class CounterWithMutex
  attr_reader :counter
  
  def initialize
    @counter = 0
    @mutex = Mutex.new
  end

  # Threadsafe with explicit locking
  def increment
    @mutex.synchronize do
      @counter += 1
    end
  end
end

cwm = CounterWithMutex.new
10.times.map { Thread.new { 1000.times { cwm.increment }}  }.map(&:join)
puts cwm.counter

class CounterActor
  include Celluloid

  attr_reader :counter

  def initialize
    @counter = 0
  end

  # Threadsafe with implicit locking thanks to Celluloid and the Actor Model
  def increment
    @counter += 1
  end
end

ca = CounterActor.new
10.times.map { Thread.new { 1000.times { ca.increment }}  }.map(&:join)
puts ca.counter
