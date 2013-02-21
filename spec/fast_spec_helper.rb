$LOAD_PATH.unshift("#{Dir.pwd}/app") unless $LOAD_PATH.include?("#{Dir.pwd}/app")
Dir['app/**/'].each do |dir|
  path = "#{Dir.pwd}/#{dir}"
  $LOAD_PATH.unshift(path) unless $LOAD_PATH.include?(path)
end

ENV["RAILS_ENV"] ||= 'test'

require 'bundler/setup'
require_relative 'config/rspec'

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
