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
  Bundler.setup
end

# For more information take a look at Spec::Runner::Configuration and Spec::Runner
Spec::Runner.configure do |config|
  config.mock_with :mocha
end

