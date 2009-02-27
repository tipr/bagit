require 'rake'
require 'rake/rdoctask'
require 'spec/rake/spectask'

Spec::Rake::SpecTask.new('spec') do |t|
  t.libs << 'lib'
  t.libs << 'spec'
  t.spec_opts << "--color"
#   t.warning = true
#   t.rcov = true
#   t.rcov_opts += ["-x /Library", "-x spec"]
end

task :default => [:spec]
