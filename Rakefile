def create_spec_tasks
  require 'rspec/core/rake_task'
  desc "Run the specs"
  RSpec::Core::RakeTask.new do |t|
    t.rspec_opts = ['--options', "spec/spec.opts"]
    t.pattern = 'spec/**/*_spec.rb'
  end
end

def stub_spec_task
  desc "Run the specs"
  task :spec do
    $stderr.puts "`gem install rspec` or `bundle install` before running the spec suite"
    exit 1
  end
end

# Try to set up the spec task as unobtrusively as possible.
begin
  create_spec_tasks
rescue LoadError
  if respond_to?(:gem)
    stub_spec_task
  else
    begin
      require 'rubygems'
      create_spec_tasks
    rescue LoadError
      stub_spec_tasks
    end
  end
end

task :default => :spec

