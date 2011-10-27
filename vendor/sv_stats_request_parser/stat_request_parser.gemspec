# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "stat_request_parser/version"

Gem::Specification.new do |s|
  s.name        = "stat_request_parser"
  s.version     = StatRequestParser::VERSION
  s.authors     = ["Thibaud Guillaume-Gentil"]
  s.email       = ["thibaud@jilion.com"]
  s.summary     = "Parse SublimeVideo stat params"
  s.description = "Extract SublimeVideo stats information for Sites & Video from stat gif request params"

  s.required_rubygems_version = '>= 1.3.6'
  s.rubyforge_project = "stat_request_parser"

  s.add_dependency 'activesupport', '>= 3.0.0'

  s.add_development_dependency 'bundler'
  s.add_development_dependency 'rspec', '~> 2.7.0'
  s.add_development_dependency 'guard-rspec'

  s.files        = Dir.glob('{lib}/**/*') + %w[README.md]
  s.test_files   = Dir.glob('{spec}/**/*')
  s.require_path = 'lib'
end
