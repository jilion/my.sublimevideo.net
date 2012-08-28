require 'abstract_unit'
require 'action_dispatch/testing/integration'

module ActionDispatch
  class RunnerTest < Test::Unit::TestCase
    class MyRunner
      include Integration::Runner

      def initialize(session)
        @integration_session = session
      end

      def hi; end
    end

    def test_respond_to?
      runner = MyRunner.new(Class.new { def x; end }.new)
      assert runner.respond_to?(:hi)
      assert runner.respond_to?(:x)
    end
  end
end
