module Revenant
  VERSION = "0.0.1"

  # Register a new type of lock.
  # User code specifies which by setting lock_type = :something
  # while configuring a Revenant::Process
  def self.register(lock_type, klass)
    @lock_types ||= {}
    if klass.respond_to?(:lock_function)
      @lock_types[lock_type.to_sym] = klass
    else
      raise ArgumentError, "#{klass} must have a `lock_function` that returns a callable object"
    end
  end

  def self.find_module(lock_type)
    @lock_types ||= {}
    @lock_types.fetch(lock_type.to_sym) do
      raise ArgumentError, "unknown lock type: #{lock_type.inspect}"
    end
  end

  def self.plugins
    @plugins ||= {}
  end

  def self.init
    require 'revenant/task'
    require_dir "locks"
    require_dir "plugins"
  end

  # Given 'locks/foo', will require ./locks/foo/*.rb' with normalized
  # (relative) paths. (e.g. require 'locks/foo/example' for example.rb)
  def self.require_dir(relative_path)
    current = File.expand_path('..', __FILE__)
    make_relative = /#{current}\//
    $LOAD_PATH << current unless $LOAD_PATH.include?(current)
    pattern = File.join(current, relative_path, '*.rb')
    Dir[pattern].each do |full_path|
      relative_name = full_path.gsub(make_relative,'').gsub(/\.rb$/,'')
      require relative_name
    end
  end

  def self.working_directory
    # If the 'PWD' environment variable points to our
    # current working directory, use it instead of Dir.pwd.
    # It may have a better name for the same destination,
    # in the presence of symlinks.
    e = File.stat(env_pwd = ENV['PWD'])
    p = File.stat(Dir.pwd)
    e.ino == p.ino && e.dev == p.dev ? env_pwd : Dir.pwd
  rescue
    Dir.pwd
  end
end

module Kernel
  def revenant(name = nil)
    unless String === name || Symbol === name
      raise ArgumentError, "Usage: task = revenant('example') {|r| configure_as_needed }"
    end
    instance = ::Revenant::Task.new(name)
    instance.daemon = true # daemonized by default if available
    yield instance if block_given?
    instance
  end
end

::Revenant.init

