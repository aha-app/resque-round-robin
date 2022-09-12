require 'rspec'

# This will force the gem to load with the jobs per fork logic enabled,
# even though we are only executing one job at a time by default
ENV["JOBS_PER_FORK"] = "1"
require 'resque-round-robin'

spec_dir = File.dirname(File.expand_path(__FILE__))
REDIS_CMD = "redis-server #{spec_dir}/redis-test.conf"

puts "Starting redis for testing at localhost:9736..."
puts `cd #{spec_dir}; #{REDIS_CMD}`
Resque.redis = 'localhost:9736'

# Schedule the redis server for shutdown when tests are all finished.
at_exit do
  pid = File.read("#{spec_dir}/redis.pid").to_i rescue nil
  system ("kill #{pid}") if pid != 0
end

class SomeJob
  def self.perform(*args)
  end
end
