# encoding: UTF-8
require 'rake'

require "bundler/setup"
require "bundler/gem_tasks"

$LOAD_PATH << "#{ENV['{PBMANAGER_ROOT']}/lib" unless ENV['PBMANAGER_ROOT'].nil?

#STDERR.puts "RUBY_VERSION is #{RUBY_VERSION}"
#STDERR.puts "Path is #{$:}"

# Load custom tasks
Dir['./tasks/*.rake'].sort.each { |f| load f }
