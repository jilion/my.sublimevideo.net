require 'abstract_unit'

# This is testing the decoupling of view renderer and view context
# by allowing the controller to be used as view context. This is
# similar to the way sinatra renders templates.
module RenderContext
  class BasicController < ActionController::Base
    self.view_paths = [ActionView::FixtureResolver.new(
      "render_context/basic/hello_world.html.erb" => "<%= @value %> from <%= self.__controller_method__ %>",
      "layouts/basic.html.erb" => "?<%= yield %>?"
    )]

    # 1) Include ActionView::Context to bring the required dependencies
    include ActionView::Context

    # 2) Call _prepare_context that will do the required initialization
    before_filter :_prepare_context

    def hello_world
      @value = "Hello"
      render :action => "hello_world", :layout => false
    end

    def with_layout
      @value = "Hello"
      render :action => "hello_world", :layout => "basic"
    end

    protected

    # 3) Set view_context to self
    def view_context
      self
    end

    def __controller_method__
      "controller context!"
    end
  end

  class RenderContextTest < Rack::TestCase
    test "rendering using the controller as context" do
      get "/render_context/basic/hello_world"
      assert_body "Hello from controller context!"
      assert_status 200
    end

    test "rendering using the controller as context with layout" do
      get "/render_context/basic/with_layout"
      assert_body "?Hello from controller context!?"
      assert_status 200
    end
  end
end
