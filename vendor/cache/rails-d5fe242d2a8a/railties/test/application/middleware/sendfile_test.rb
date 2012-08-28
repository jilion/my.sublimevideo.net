require 'isolation/abstract_unit'

module ApplicationTests
  class SendfileTest < Test::Unit::TestCase
    include ActiveSupport::Testing::Isolation

    def setup
      build_app
      boot_rails
      FileUtils.rm_rf "#{app_path}/config/environments"
    end

    def teardown
      teardown_app
    end

    def app
      @app ||= Rails.application
    end

    define_method :simple_controller do
      class ::OmgController < ActionController::Base
        def index
          send_file __FILE__
        end
      end
    end

    # x_sendfile_header middleware
    test "config.action_dispatch.x_sendfile_header defaults to nil" do
      make_basic_app
      simple_controller

      get "/"
      assert !last_response.headers["X-Sendfile"]
      assert_equal File.read(__FILE__), last_response.body
    end

    test "config.action_dispatch.x_sendfile_header can be set" do
      make_basic_app do |app|
        app.config.action_dispatch.x_sendfile_header = "X-Sendfile"
      end

      simple_controller

      get "/"
      assert_equal File.expand_path(__FILE__), last_response.headers["X-Sendfile"]
    end

    test "config.action_dispatch.x_sendfile_header is sent to Rack::Sendfile" do
      make_basic_app do |app|
        app.config.action_dispatch.x_sendfile_header = 'X-Lighttpd-Send-File'
      end

      simple_controller

      get "/"
      assert_equal File.expand_path(__FILE__), last_response.headers["X-Lighttpd-Send-File"]
    end
  end
end
