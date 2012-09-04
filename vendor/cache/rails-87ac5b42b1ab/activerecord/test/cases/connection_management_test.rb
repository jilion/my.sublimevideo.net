require "cases/helper"

module ActiveRecord
  module ConnectionAdapters
    class ConnectionManagementTest < ActiveRecord::TestCase
      class App
        attr_reader :calls
        def initialize
          @calls = []
        end

        def call(env)
          @calls << env
          [200, {}, ['hi mom']]
        end
      end

      def setup
        @env = {}
        @app = App.new
        @management = ConnectionManagement.new(@app)

        # make sure we have an active connection
        assert ActiveRecord::Base.connection
        assert ActiveRecord::Base.connection_handler.active_connections?
      end

      def test_app_delegation
        manager = ConnectionManagement.new(@app)

        manager.call @env
        assert_equal [@env], @app.calls
      end

      def test_connections_are_active_after_call
        @management.call(@env)
        assert ActiveRecord::Base.connection_handler.active_connections?
      end

      def test_body_responds_to_each
        _, _, body = @management.call(@env)
        bits = []
        body.each { |bit| bits << bit }
        assert_equal ['hi mom'], bits
      end

      def test_connections_are_cleared_after_body_close
        _, _, body = @management.call(@env)
        body.close
        assert !ActiveRecord::Base.connection_handler.active_connections?
      end

      def test_active_connections_are_not_cleared_on_body_close_during_test
        @env['rack.test'] = true
        _, _, body = @management.call(@env)
        body.close
        assert ActiveRecord::Base.connection_handler.active_connections?
      end

      def test_connections_closed_if_exception
        app       = Class.new(App) { def call(env); raise; end }.new
        explosive = ConnectionManagement.new(app)
        assert_raises(RuntimeError) { explosive.call(@env) }
        assert !ActiveRecord::Base.connection_handler.active_connections?
      end

      def test_connections_not_closed_if_exception_and_test
        @env['rack.test'] = true
        app               = Class.new(App) { def call(env); raise; end }.new
        explosive         = ConnectionManagement.new(app)
        assert_raises(RuntimeError) { explosive.call(@env) }
        assert ActiveRecord::Base.connection_handler.active_connections?
      end

      test "doesn't clear active connections when running in a test case" do
        @env['rack.test'] = true
        @management.call(@env)
        assert ActiveRecord::Base.connection_handler.active_connections?
      end

      test "proxy is polite to it's body and responds to it" do
        body = Class.new(String) { def to_path; "/path"; end }.new
        proxy = ConnectionManagement::Proxy.new(body)
        assert proxy.respond_to?(:to_path)
        assert_equal proxy.to_path, "/path"
      end
    end
  end
end
