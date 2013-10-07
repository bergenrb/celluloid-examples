require 'benchmark'

require 'celluloid/autostart'

class SayActor
  include Celluloid

  VOICES = %w(Agnes Albert Alex Bahh Bells Boing Kathy Junior Princess Ralph)

  def initialize(voice=nil)
    @voice = voice || VOICES.shuffle.first
  end

  def say(text="Hello world")
    Benchmark.realtime do
      `say --voice=#{@voice} #{text}`
    end
  end
end

# speaker_pool = SayActor.pool # defaults to number of cores
# futures = 10.times.map { |i| speaker_pool.future.say(i) } # distribute work accross the pool
# futures.map(&:value).reduce(&:+)
