$LOAD_PATH.unshift("#{Dir.pwd}/app") unless $LOAD_PATH.include?("#{Dir.pwd}/app")

require 'bundler/setup'
require_relative 'config/rspec'

def require_dependency(file_name, message = "No such file to load -- %s")
  unless file_name.is_a?(String)
    raise ArgumentError, "the file name must be a String -- you passed #{file_name.inspect}"
  end
  if defined? ActiveSupport::Dependencies
    ActiveSupport::Dependencies.depend_on(file_name, false, message)
  else
    require file_name
  end
end

unless defined?(Rails)
  module Rails
    def self.root; Pathname.new(File.expand_path('')); end
    def self.env; 'test'; end
  end
end

unless defined?(Librato)
  module Librato
    def self.method_missing(*args)
      true
    end
  end
end
