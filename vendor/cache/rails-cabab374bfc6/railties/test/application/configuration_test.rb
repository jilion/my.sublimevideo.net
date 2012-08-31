require "isolation/abstract_unit"
require 'rack/test'

class ::MyMailInterceptor
  def self.delivering_email(email); email; end
end

class ::MyOtherMailInterceptor < ::MyMailInterceptor; end

class ::MyMailObserver
  def self.delivered_email(email); email; end
end

class ::MyOtherMailObserver < ::MyMailObserver; end

module ApplicationTests
  class ConfigurationTest < Test::Unit::TestCase
    include ActiveSupport::Testing::Isolation
    include Rack::Test::Methods

    def new_app
      File.expand_path("#{app_path}/../new_app")
    end

    def copy_app
      FileUtils.cp_r(app_path, new_app)
    end

    def app
      @app ||= Rails.application
    end

    def setup
      build_app
      boot_rails
      FileUtils.rm_rf("#{app_path}/config/environments")
    end

    def teardown
      teardown_app
      FileUtils.rm_rf(new_app) if File.directory?(new_app)
    end

    test "Rails.groups returns available groups" do
      require "rails"

      Rails.env = "development"
      assert_equal [:default, "development"], Rails.groups
      assert_equal [:default, "development", :assets], Rails.groups(:assets => [:development])
      assert_equal [:default, "development", :another, :assets], Rails.groups(:another, :assets => %w(development))

      Rails.env = "test"
      assert_equal [:default, "test"], Rails.groups(:assets => [:development])

      ENV["RAILS_GROUPS"] = "javascripts,stylesheets"
      assert_equal [:default, "test", "javascripts", "stylesheets"], Rails.groups
    end

    test "Rails.application is nil until app is initialized" do
      require 'rails'
      assert_nil Rails.application
      require "#{app_path}/config/environment"
      assert_equal AppTemplate::Application.instance, Rails.application
    end

    test "Rails.application responds to all instance methods" do
      require "#{app_path}/config/environment"
      assert_respond_to Rails.application, :routes_reloader
      assert_equal Rails.application.routes_reloader, AppTemplate::Application.routes_reloader
    end

    test "Rails::Application responds to paths" do
      require "#{app_path}/config/environment"
      assert_respond_to AppTemplate::Application, :paths
      assert_equal AppTemplate::Application.paths["app/views"].expanded, ["#{app_path}/app/views"]
    end

    test "the application root is set correctly" do
      require "#{app_path}/config/environment"
      assert_equal Pathname.new(app_path), Rails.application.root
    end

    test "the application root can be seen from the application singleton" do
      require "#{app_path}/config/environment"
      assert_equal Pathname.new(app_path), AppTemplate::Application.root
    end

    test "the application root can be set" do
      copy_app
      add_to_config <<-RUBY
        config.root = '#{new_app}'
      RUBY

      use_frameworks []

      require "#{app_path}/config/environment"
      assert_equal Pathname.new(new_app), Rails.application.root
    end

    test "the application root is Dir.pwd if there is no config.ru" do
      File.delete("#{app_path}/config.ru")

      use_frameworks []

      Dir.chdir("#{app_path}") do
        require "#{app_path}/config/environment"
        assert_equal Pathname.new("#{app_path}"), Rails.application.root
      end
    end

    test "Rails.root should be a Pathname" do
      add_to_config <<-RUBY
        config.root = "#{app_path}"
      RUBY
      require "#{app_path}/config/environment"
      assert_instance_of Pathname, Rails.root
    end

    test "marking the application as threadsafe sets the correct config variables" do
      add_to_config <<-RUBY
        config.threadsafe!
      RUBY

      require "#{app_path}/config/application"
      assert AppTemplate::Application.config.allow_concurrency
    end

    test "asset_path defaults to nil for application" do
      require "#{app_path}/config/environment"
      assert_equal nil, AppTemplate::Application.config.asset_path
    end

    test "the application can be marked as threadsafe when there are no frameworks" do
      FileUtils.rm_rf("#{app_path}/config/environments")
      add_to_config <<-RUBY
        config.threadsafe!
      RUBY

      use_frameworks []

      assert_nothing_raised do
        require "#{app_path}/config/application"
      end
    end

    test "frameworks are not preloaded by default" do
      require "#{app_path}/config/environment"

      assert ActionController.autoload?(:RecordIdentifier)
    end

    test "frameworks are preloaded with config.preload_frameworks is set" do
      add_to_config <<-RUBY
        config.preload_frameworks = true
      RUBY

      require "#{app_path}/config/environment"

      assert !ActionController.autoload?(:RecordIdentifier)
    end

    test "filter_parameters should be able to set via config.filter_parameters" do
      add_to_config <<-RUBY
        config.filter_parameters += [ :foo, 'bar', lambda { |key, value|
          value = value.reverse if key =~ /baz/
        }]
      RUBY

      assert_nothing_raised do
        require "#{app_path}/config/application"
      end
    end

    test "config.to_prepare is forwarded to ActionDispatch" do
      $prepared = false

      add_to_config <<-RUBY
        config.to_prepare do
          $prepared = true
        end
      RUBY

      assert !$prepared

      require "#{app_path}/config/environment"

      get "/"
      assert $prepared
    end

    def assert_utf8
      if RUBY_VERSION < '1.9'
        assert_equal "UTF8", $KCODE
      else
        assert_equal Encoding::UTF_8, Encoding.default_external
        assert_equal Encoding::UTF_8, Encoding.default_internal
      end
    end

    test "skipping config.encoding still results in 'utf-8' as the default" do
      require "#{app_path}/config/application"
      assert_utf8
    end

    test "config.encoding sets the default encoding" do
      add_to_config <<-RUBY
        config.encoding = "utf-8"
      RUBY

      require "#{app_path}/config/application"
      assert_utf8
    end

    test "config.paths.public sets Rails.public_path" do
      add_to_config <<-RUBY
        config.paths["public"] = "somewhere"
      RUBY

      require "#{app_path}/config/application"
      assert_equal File.join(app_path, "somewhere"), Rails.public_path
    end

    test "config.secret_token is sent in env" do
      make_basic_app do |app|
        app.config.secret_token = 'b3c631c314c0bbca50c1b2843150fe33'
        app.config.session_store :disabled
      end

      class ::OmgController < ActionController::Base
        def index
          cookies.signed[:some_key] = "some_value"
          render :text => env["action_dispatch.secret_token"]
        end
      end

      get "/"
      assert_equal 'b3c631c314c0bbca50c1b2843150fe33', last_response.body
    end

    test "protect from forgery is the default in a new app" do
      make_basic_app

      class ::OmgController < ActionController::Base
        def index
          render :inline => "<%= csrf_meta_tags %>"
        end
      end

      get "/"
      assert last_response.body =~ /csrf\-param/
    end

    test "request forgery token param can be changed" do
      make_basic_app do
        app.config.action_controller.request_forgery_protection_token = '_xsrf_token_here'
      end

      class ::OmgController < ActionController::Base
        def index
          render :inline => "<%= csrf_meta_tags %>"
        end
      end

      get "/"
      assert last_response.body =~ /_xsrf_token_here/
    end

    test "config.action_controller.perform_caching = true" do
      make_basic_app do |app|
        app.config.action_controller.perform_caching = true
      end

      class ::OmgController < ActionController::Base
        @@count = 0

        caches_action :index
        def index
          @@count += 1
          render :text => @@count
        end
      end

      get "/"
      res = last_response.body
      get "/"
      assert_equal res, last_response.body # value should be unchanged
    end

    test "sets ActionDispatch::Response.default_charset" do
      make_basic_app do |app|
        app.config.action_dispatch.default_charset = "utf-16"
      end

      assert_equal "utf-16", ActionDispatch::Response.default_charset
    end

    test "sets all Active Record models to whitelist all attributes by default" do
      add_to_config <<-RUBY
        config.active_record.whitelist_attributes = true
      RUBY

      require "#{app_path}/config/environment"

      assert_equal ActiveModel::MassAssignmentSecurity::WhiteList,
                   ActiveRecord::Base.active_authorizers[:default].class
      assert_equal [""], ActiveRecord::Base.active_authorizers[:default].to_a
    end

    test "registers interceptors with ActionMailer" do
      add_to_config <<-RUBY
        config.action_mailer.interceptors = MyMailInterceptor
      RUBY

      require "#{app_path}/config/environment"
      require "mail"

      _ = ActionMailer::Base

      assert_equal [::MyMailInterceptor], ::Mail.send(:class_variable_get, "@@delivery_interceptors")
    end

    test "registers multiple interceptors with ActionMailer" do
      add_to_config <<-RUBY
        config.action_mailer.interceptors = [MyMailInterceptor, "MyOtherMailInterceptor"]
      RUBY

      require "#{app_path}/config/environment"
      require "mail"

      _ = ActionMailer::Base

      assert_equal [::MyMailInterceptor, ::MyOtherMailInterceptor], ::Mail.send(:class_variable_get, "@@delivery_interceptors")
    end

    test "registers observers with ActionMailer" do
      add_to_config <<-RUBY
        config.action_mailer.observers = MyMailObserver
      RUBY

      require "#{app_path}/config/environment"
      require "mail"

      _ = ActionMailer::Base

      assert_equal [::MyMailObserver], ::Mail.send(:class_variable_get, "@@delivery_notification_observers")
    end

    test "registers multiple observers with ActionMailer" do
      add_to_config <<-RUBY
        config.action_mailer.observers = [MyMailObserver, "MyOtherMailObserver"]
      RUBY

      require "#{app_path}/config/environment"
      require "mail"

      _ = ActionMailer::Base

      assert_equal [::MyMailObserver, ::MyOtherMailObserver], ::Mail.send(:class_variable_get, "@@delivery_notification_observers")
    end

    test "valid timezone is setup correctly" do
      add_to_config <<-RUBY
        config.root = "#{app_path}"
          config.time_zone = "Wellington"
      RUBY

      require "#{app_path}/config/environment"

      assert_equal "Wellington", Rails.application.config.time_zone
    end

    test "raises when an invalid timezone is defined in the config" do
      add_to_config <<-RUBY
        config.root = "#{app_path}"
          config.time_zone = "That big hill over yonder hill"
      RUBY

      assert_raise(ArgumentError) do
        require "#{app_path}/config/environment"
      end
    end

    test "config.action_controller.perform_caching = false" do
      make_basic_app do |app|
        app.config.action_controller.perform_caching = false
      end

      class ::OmgController < ActionController::Base
        @@count = 0

        caches_action :index
        def index
          @@count += 1
          render :text => @@count
        end
      end

      get "/"
      res = last_response.body
      get "/"
      assert_not_equal res, last_response.body
    end

    test "config.asset_path is not passed through env" do
      make_basic_app do |app|
        app.config.asset_path = "/omg%s"
      end

      class ::OmgController < ActionController::Base
        def index
          render :inline => "<%= image_path('foo.jpg') %>"
        end
      end

      get "/"
      assert_equal "/omg/images/foo.jpg", last_response.body
    end

    test "config.action_view.cache_template_loading with cache_classes default" do
      add_to_config "config.cache_classes = true"
      require "#{app_path}/config/environment"
      require 'action_view/base'

      assert ActionView::Resolver.caching?
    end

    test "config.action_view.cache_template_loading without cache_classes default" do
      add_to_config "config.cache_classes = false"
      require "#{app_path}/config/environment"
      require 'action_view/base'

      assert !ActionView::Resolver.caching?
    end

    test "config.action_view.cache_template_loading = false" do
      add_to_config <<-RUBY
        config.cache_classes = true
        config.action_view.cache_template_loading = false
      RUBY
      require "#{app_path}/config/environment"
      require 'action_view/base'

      assert !ActionView::Resolver.caching?
    end

    test "config.action_view.cache_template_loading = true" do
      add_to_config <<-RUBY
        config.cache_classes = false
        config.action_view.cache_template_loading = true
      RUBY
      require "#{app_path}/config/environment"
      require 'action_view/base'

      assert ActionView::Resolver.caching?
    end

    test "config.action_dispatch.show_exceptions is sent in env" do
      make_basic_app do |app|
        app.config.action_dispatch.show_exceptions = true
      end

      class ::OmgController < ActionController::Base
        def index
          render :text => env["action_dispatch.show_exceptions"]
        end
      end

      get "/"
      assert_equal 'true', last_response.body
    end

    test "config.action_controller.wrap_parameters is set in ActionController::Base" do
      app_file 'config/initializers/wrap_parameters.rb', <<-RUBY
        ActionController::Base.wrap_parameters :format => [:json]
      RUBY

      app_file 'app/models/post.rb', <<-RUBY
      class Post
        def self.attribute_names
          %w(title)
        end
      end
      RUBY

      app_file 'app/controllers/posts_controller.rb', <<-RUBY
      class PostsController < ApplicationController
        def create
          render :text => params[:post].inspect
        end
      end
      RUBY

      add_to_config <<-RUBY
        routes.prepend do
          resources :posts
        end
      RUBY

      require "#{app_path}/config/environment"

      post "/posts.json", '{ "title": "foo", "name": "bar" }', "CONTENT_TYPE" => "application/json"
      assert_equal '{"title"=>"foo"}', last_response.body
    end

    test "config.action_dispatch.ignore_accept_header" do
      make_basic_app do |app|
        app.config.action_dispatch.ignore_accept_header = true
      end

      class ::OmgController < ActionController::Base
        def index
          respond_to do |format|
            format.html { render :text => "HTML" }
            format.xml { render :text => "XML" }
          end
        end
      end

      get "/", {}, "HTTP_ACCEPT" => "application/xml"
      assert_equal 'HTML', last_response.body

      get "/", { :format => :xml }, "HTTP_ACCEPT" => "application/xml"
      assert_equal 'XML', last_response.body
    end

    test "Rails.application#env_config exists and include some existing parameters" do
      make_basic_app

      assert_respond_to app, :env_config
      assert_equal      app.env_config['action_dispatch.parameter_filter'],  app.config.filter_parameters
      assert_equal      app.env_config['action_dispatch.secret_token'],      app.config.secret_token
      assert_equal      app.env_config['action_dispatch.show_exceptions'],   app.config.action_dispatch.show_exceptions
      assert_equal      app.env_config['action_dispatch.logger'],            Rails.logger
      assert_equal      app.env_config['action_dispatch.backtrace_cleaner'], Rails.backtrace_cleaner
    end
  end
end
