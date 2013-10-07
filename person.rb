require 'celluloid/autostart'

class Person
  include Celluloid

  attr_reader :name
  attr_writer :status

  def initialize(name="No name")
    @name = name
  end

  def status
    @status || 'No status set'
  end

  def wait_for_messages
    loop do
      status = receive { |msg| msg.kind_of?(String) }
      @status = status
    end
  end

  def actor
    Actor.current # the wrapped object, don't pass around `self`!
  end

  def identity
    [self, actor]
  end
  
  def report
    [name, status].join(': ')
  end
end
