def create_spec_tasks
  require 'spec/rake/spectask'
  desc "Run the specs"
  Spec::Rake::SpecTask.new do |t|
    t.spec_opts = ['--options', "spec/spec.opts"]
    t.spec_files = FileList['spec/**/*_spec.rb']
  end

  namespace :spec do
    desc "Run all specs in spec directory with RCov"
    Spec::Rake::SpecTask.new(:rcov) do |t|
      t.spec_opts = ['--options', "spec/spec.opts"]
      t.spec_files = FileList['spec/**/*_spec.rb']
      t.rcov = true
      t.rcov_opts = ['--exclude "spec/*,gems/*"']
    end
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

