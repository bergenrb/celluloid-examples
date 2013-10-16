# Adapted from the Akka/Scala example in Prag Prog's excellent
# "Programming Concurrency on the JVM"
#
# This is a more idiomatic implementation using Celluloid's actor pool support.

require 'celluloid/autostart'

class SizeCollector
  include Celluloid

  attr_reader :total_size, :pending_number_of_files_to_visit

  def initialize
    @worker_pool = FileProcessor.pool
    @file_names_to_process = []
    @start = Time.now
    @total_size = 0
    @pending_number_of_files_to_visit = 0
  end

  def add_file_to_process(file_name)
    puts "Add file: #{file_name}"
    @file_names_to_process << file_name
    @pending_number_of_files_to_visit += 1
    send_a_file_to_process
  end

  def add_file_size(file_size)
    puts "Add file size: #{file_size}"
    @total_size += file_size
    @pending_number_of_files_to_visit -= 1
    puts "Remaining: #{@pending_number_of_files_to_visit}"

    if done?
      puts "DONE! Completed in #{Time.now - @start}"
    end
  end

  def done?
    @pending_number_of_files_to_visit == 0
  end

  private
  
  def send_a_file_to_process
    @worker_pool.async.process_file(@file_names_to_process.pop.to_s, Actor.current)
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

  def process_file(file_name, size_collector)
    size = 0
    if File.file?(file_name)
      size = File.size(file_name)
    elsif File.directory?(file_name)
      entries = Dir.glob("#{file_name}/*") + Dir.glob("#{file_name}/.*").reject { |f| f.match(/\.\.?$/) }
      entries.each { |f| size_collector.async.add_file_to_process(f) }
    else
      return
    end

    size_collector.async.add_file_size(size)
    size
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
