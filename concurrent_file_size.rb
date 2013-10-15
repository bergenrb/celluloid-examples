# Adapted from the Akka/Scala example in Prag Prog's excellent
# "Programming Concurrency on the JVM"

require 'celluloid/autostart'

class SizeCollector
  include Celluloid

  attr_reader :total_size, :pending_number_of_files_to_visit

  def initialize
    @idle_file_processors = []
    @file_names_to_process = []
    @start = Time.now
    @total_size = 0
    @pending_number_of_files_to_visit = 0
  end

  def register_worker(file_processor)
    @idle_file_processors << file_processor
    async.send_a_file_to_process
  end

  def add_file_to_process(file_name)
    puts "Add file: #{file_name}"
    @file_names_to_process << file_name
    @pending_number_of_files_to_visit += 1
    async.send_a_file_to_process
  end

  def send_a_file_to_process
    return if @idle_file_processors.empty? && @file_names_to_process.empty?
    worker = @idle_file_processors.pop
    if worker
      worker.async.process_file(@file_names_to_process.pop.to_s)
    end
  end

  def add_file_size(file_size)
    puts "Add file size: #{file_size}"
    @total_size += file_size
    @pending_number_of_files_to_visit -= 1
    puts "Remaining: #{@pending_number_of_files_to_visit}"
  end

  def done?
    @pending_number_of_files_to_visit == 0
  end
end

# FileProcessors are the workers with the job to explore a given directory and
# send back the total size of files and names of subdirectories they find. Once
# they finish that task, they send the RequestAFile class to let SizeCollector
# know they're ready to take on the task of exploring another directory. They
# also need to register with SizeCollector in the first place to receive the
# first directory to explore.
class FileProcessor
  include Celluloid

  def initialize(size_collector)
    @size_collector = size_collector
    register_to_get_file
  end

  def process_file(file_name)
    size = 0
    if File.file?(file_name)
      size = File.size(file_name)
    elsif File.directory?(file_name)
      entries = Dir.glob("#{file_name}/*") + Dir.glob("#{file_name}/.*").reject { |f| f.match(/\.\.?$/) }
      entries.each { |f| @size_collector.async.add_file_to_process(f) }
    else
      return
    end

    @size_collector.async.add_file_size(size)
    register_to_get_file
    size
  end

  private
  def register_to_get_file
    @size_collector.async.register_worker(Actor.current)
  end
end


class ConcurrentFileSize
  def initialize
    @size_collector = SizeCollector.new
  end

  def run
    unless ARGV[0]
      puts "Usage: #{$0} PATH"
      exit 1
    end

    @size_collector.add_file_to_process(ARGV[0])

    5.times { FileProcessor.new(@size_collector) }

    until @size_collector.done?
      sleep 1
      puts
      puts "Pending: #{@size_collector.pending_number_of_files_to_visit}"
      puts "Total: #{@size_collector.total_size}"
      puts
    end
  end
end

if __FILE__ == $0
  ConcurrentFileSize.new.run
end
