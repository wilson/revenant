module Revenant
  VERSION = "0.0.1"

  # Register a new type of lock.
  # User code specifies which by setting lock_type = :something
  # while configuring a Revenant::Process
  def self.register(lock_type, klass)
    @lock_types ||= {}
    @lock_types[lock_type.to_sym] = klass
  end

  def self.find_module(lock_type)
    @lock_types ||= {}
    @lock_types.fetch(lock_type.to_sym) do
      raise ArgumentError, "unknown lock type: #{lock_type.inspect}"
    end
  end
end

require 'time'
current = File.expand_path('..', __FILE__)
make_relative = /#{current}\//
$: << current unless $:.include?(current)
Dir["#{current}/locks/*.rb"].each do |full_path|
  require full_path.gsub(make_relative,'').gsub(/\.rb$/,'')
end

module Kernel
  def revenant(name = nil)
    unless name.respond_to?(:to_sym)
      raise ArgumentError, "Usage: task = revenant('example') {|r| #config }"
    end
    require 'revenant/task'
    instance = Revenant::Task.new(name)
    yield instance if block_given?
    instance
  end
end

