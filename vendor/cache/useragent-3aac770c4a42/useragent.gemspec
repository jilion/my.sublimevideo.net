# -*- encoding: utf-8 -*-
$:.push File.expand_path('../lib', __FILE__)
require 'user_agent/version'

Gem::Specification.new do |s|
  s.name        = 'useragent'
  s.version     = UserAgent::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ['Joshua Peek', 'Rémy Coutable']
  s.email       = ['josh@joshpeek.com', 'remy@jilion.com']
  s.homepage    = 'https://github.com/jilion/useragent'
  s.summary     = 'HTTP User Agent parser.'
  s.description = 'UserAgent is a Ruby library that parses and compares HTTP User Agents.'

  s.rubyforge_project = 'useragent'

  s.files         = Dir.glob('{lib}/**/*') + %w[CHANGELOG.md LICENSE README.md]
  s.test_files    = Dir.glob('{spec}/**/*')
  s.require_paths = ['lib']

  s.add_development_dependency 'rspec'
end
