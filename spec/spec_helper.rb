root = File.expand_path('../..', __FILE__)
$:.unshift File.join(root, 'lib')
require 'revenant'

begin
  # Try to require the preresolved locked set of gems.
  require File.expand_path('../../.bundle/environment', __FILE__)
rescue LoadError
  # Fall back on doing an unlocked resolve at runtime.
  require "rubygems"
  require "bundler"
  Bundler.setup(:default, :test)
end

require 'rspec'
require File.expand_path('../mock_helper', __FILE__)

RSpec.configure do |config|
  config.mock_with :absolutely_nothing
end

