# We do this ourselves because RSpec itself
# loads deprecated Mocha stuff.
# See https://github.com/rspec/rspec-core/blob/master/lib/rspec/core/mocking/with_absolutely_nothing.rb
require 'mocha/api'

module RSpec
  module Core
    module MockFrameworkAdapter
      def self.framework_name; :mocha end
      include Mocha::API

      def setup_mocks_for_rspec
        mocha_setup
      end

      def verify_mocks_for_rspec
        mocha_verify
      end

      def teardown_mocks_for_rspec
        mocha_teardown
      end
    end
  end
end
