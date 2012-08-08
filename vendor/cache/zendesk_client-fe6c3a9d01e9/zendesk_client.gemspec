# -*- encoding: utf-8 -*-
$:.unshift File.expand_path("../lib", __FILE__)
require "zendesk/version"

Gem::Specification.new do |s|
  s.name        = 'zendesk_client'
  s.version     = Zendesk::VERSION.dup
  s.authors     = ['Dylan Clendenin']
  s.email       = ['dclendenin@zendesk.com']
  s.homepage    = 'https://github.com/zendesk/zendesk_client'
  s.summary     = 'A Ruby client for the Zendesk REST API'
  s.description = 'A Ruby client for the Zendesk REST API'

  s.required_rubygems_version = '>= 1.3.6'

  s.add_dependency "hashie",             "~> 1.2.0"
  s.add_dependency "faraday",            "~> 0.8.0"
  s.add_dependency "faraday_middleware", "~> 0.8.7"
  s.add_dependency "multi_xml",          "~> 0.4.4"
  s.add_dependency "multi_json",         "~> 1.3.4"
  s.add_dependency "patron"

  s.add_development_dependency "yajl-ruby", "~> 0.8.2"
  s.add_development_dependency "nokogiri",  "~> 1.4"
  s.add_development_dependency "rake",      "~> 0.8"
  s.add_development_dependency "webmock",   "~> 1.6"
  s.add_development_dependency "yard",      "~> 0.7"
  s.add_development_dependency "minitest"
  s.add_development_dependency "pry"

  s.files        = Dir.glob('{lib}/**/*') + %w[README.md]
  s.require_path = 'lib'
end
