require 'rubygems'
require 'bundler/setup'
Bundler.setup(:default, :development, :test)

require 'rake'
require 'rdoc/task'
require 'rspec/core/rake_task'

Bundler::GemHelper.install_tasks

RSpec::Core::RakeTask.new do |t|
  t.pattern = 'spec/**/*_spec.rb'
  t.rspec_opts = %w(-fs --color)
end

task :default => [:spec]
