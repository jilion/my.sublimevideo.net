module Rack
  class EnsureSsl
    def initialize(app)
      @app = app
    end
    
    def call(env)
      ssl_request?(env) ? @app.call(env) : ssl_redirect(env)
    end
    
  private
    def ssl_request?(env)
      (env['HTTP_X_FORWARDED_PROTO'] || env['rack.url_scheme']) == "https"
    end
    
     def ssl_location(env)
      "https://" + env['HTTP_HOST'] + env['PATH_INFO']
    end
    
    def ssl_redirect(env)
      [
        301,
        {
          'Content-Type' => 'text/html',
          'Location' => ssl_location(env)
        },
%{
<html>
<head>
<title>SSL Redirect</title>
</head>
<body>
<p>The requested path must be requested via SSL. You are now being redirected.</p>
</body>
</html>
}
    ]
    end
  end
end
