require 'rake'
require 'rake/rdoctask'
require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new do |t|
  t.pattern = 'spec/**/*.rb'
  t.rspec_opts = %w(-fs --color)
end

task :default => [:spec]
