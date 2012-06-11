begin
  # use `bundle install --standalone' to get this...
  require_relative '../bundle/bundler/setup'
rescue LoadError
  # fall back to regular bundler if the developer hasn't bundled standalone
  require 'bundler'
  Bundler.setup
end

require_relative 'config/rspec'

def require_dependency(file)
  require(file)
end

unless defined?(Rails)
  module Rails
    def self.root; Pathname.new('path'); end
    def self.env; ''; end
  end
end
