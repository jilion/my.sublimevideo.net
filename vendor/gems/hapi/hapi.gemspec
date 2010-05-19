Gem::Specification.new do |s|
  s.name = "hapi"
  s.version = "1.0.5"
  s.author = "James W. Brinkerhoff"
  s.email = "jwb@voxel.net"
  s.homepage = "http://voxel.net/"
  # s.executables = [ "rhapi" ]
  s.summary = "A Ruby Class Interface to Voxel\'s hAPI"
  # s.files = Dir['lib/**/*.rb'] + Dir['bin/*'] + Dir['examples/*']
  s.files = Dir['lib/**/*.rb']
  # { 'ParaOpts' => '>= 1.0.0', 'xml-simple' => '>= 1.0.12', 'libxml-ruby' => '>= 1.0.3' }.each_pair do |name, ver|
  #   s.add_dependency(name, ver)
  # end
  { 'xml-simple' => '>= 1.0.12', 'libxml-ruby' => '>= 1.0.3' }.each_pair do |name, ver|
    s.add_dependency(name, ver)
  end
  s.has_rdoc = false
end

