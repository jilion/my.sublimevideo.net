# -*- encoding: utf-8 -*-
$LOAD_PATH.unshift File.expand_path('../lib', __FILE__)
require 'voxel_hapi/version'

Gem::Specification.new do |s|
  s.name        = "voxel_hapi"
  s.version     = VoxelHAPI::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["James W. Brinkerhoff"]
  s.email       = ["jwb@voxel.net"]
  s.homepage    = "http://voxel.net/"
  s.summary     = "A Ruby Class Interface to Voxel\'s hAPI"

  s.required_rubygems_version = ">= 1.3.6"
  s.rubyforge_project         = "voxel_hapi"

  s.add_dependency 'xml-simple',  '~> 1.0.12'
  s.add_dependency 'libxml-ruby', '~> 2.2.0'
  s.add_dependency 'rescue_me',   '~> 0.1.0'

  s.add_development_dependency 'bundler', '>= 1.0.0'
  s.add_development_dependency 'rspec',   '>= 2.0.0'
  s.add_development_dependency 'rake'

  s.files        = Dir['lib/**/*.rb']
  s.require_path = 'lib'
end
