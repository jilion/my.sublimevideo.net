module Rack
  class Private

    def initialize(app, options = {})
      @app = app
      @options = options
    end

    def call(env)
      request = Rack::Request.new(env)

      # Check code in session and return Rails call if is valid
      return @app.call(env) if already_auth?(request)

      # If post method check :code_param value
      if request.post? && code_valid?(request.params["private_code"])
        request.session[:private_code] = request.params["private_code"]
        body = "<html><body>Secret code is valid.</body></html>"
        [307, { 'Content-Type' => 'text/html', 'Location' => '/' }, [body]] # Redirect if code is valid
      elsif request.path == '/private'
        render_private_form
      else
        location = "http://jilion.com/sublimevideo-maintenance"
        body     = "<html><body>You are being <a href=\"#{location}\">redirected</a>.</body></html>"
        [301, { 'Content-Type' => 'text/html', 'Location' => location }, [body]]
      end
    end

  private
    # Render staging html file
    def render_private_form
      [200, {'Content-Type' => 'text/html'}, [
        ::File.open(html_template, 'rb').read
      ]]
    end

    def html_template
      @options[:template_path] || ::File.expand_path('../private/index.html', __FILE__)
    end

    # Validate code
    def code_valid?(code)
      [@options[:code] || @options[:codes]].flatten.include?(code)
    end

    def already_auth?(request)
      code_valid?(request.session[:private_code])
    end
  end
end

