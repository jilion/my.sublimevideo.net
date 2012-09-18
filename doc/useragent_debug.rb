require 'rubygems'

# Set up gems listed in the Gemfile.
ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../../Gemfile', __FILE__)

require 'bundler/setup' if File.exists?(ENV['BUNDLE_GEMFILE'])
require 'useragent'

i, y = 0, 0
File.open('4076.voxcdn.com.log.1347968520-1347968580').each_line do |line|
  i += 1
  if matches = line.match(/\"Mozilla[^"]+\"/)
    y += 1
    useragent_string = matches[0]
    # print "#{useragent_string} => "
    useragent = UserAgent.parse(useragent_string)
    # puts useragent.send(:version)
  else
    puts "#{i} : #{line}"
  end
end

puts i
puts y
