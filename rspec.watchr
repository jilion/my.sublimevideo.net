# Run me with:
#
# $ watchr rspec.watchr

require 'growl'

# --------------------------------------------------
# Convenience Methods
# --------------------------------------------------
def all_spec_files
  Dir['spec/**/*_spec.rb']
end

def run_spec_matching(thing_to_match)
  puts thing_to_match
  matches = all_spec_files.grep(/#{thing_to_match}/i)
  if matches.empty?
    puts "Sorry, thanks for playing, but there were no matches for #{thing_to_match}"  
  else
    run matches.join(' ')
  end
end

def run(files_to_run, options = {})
  system("clear")
  puts(options[:message] || "Running: #{files_to_run}")
  output = %x(bundle exec rspec -c -f progress #{files_to_run})
  puts output
  growl_notify(output)
end

def run_all_specs
  run(all_spec_files.join(' '), :message => " --- Running all specs --- ")
end

# CustomFormatter not yet supported
# def growl_formatter
#   " --require #{File.dirname(__FILE__)}/spec/watchr/rspec_growler.rb --format RSpecGrowler:STDOUT"
# end

def growl_notify(output)
  title = 'Spec Results'
  summary = output.slice(/(\d+)\s+examples?,\s*(\d+)\s+failures?(,\s*(\d+)\s+not implemented)?/)
  if summary
    total, failures, pending = $~[1].to_i, $~[2].to_i, $~[3].to_i
    message = "#{total} examples, #{failures} failures"
    message << " (#{pending} pending)" if pending > 0
    if failures > 0
      Growl.notify message, :title => title, :icon => 'spec/watchr/images/failed.png'
    elsif pending > 0
      Growl.notify message, :title => title, :icon => 'spec/watchr/images/pending.png'
    else # success
      Growl.notify message, :title => title, :icon => 'spec/watchr/images/success.png'
    end
  end
end

# --------------------------------------------------
# Watchr Rules
# --------------------------------------------------

watch('^app/controllers/(.*)\.rb') { |m| run_spec_matching("controllers/#{m[1]}") }
watch('^app/models/(.*)\.rb')      { |m| run_spec_matching("models/#{m[1]}") }
watch('^spec/(.*)_spec\.rb')       { |m| run_spec_matching(m[1]) }
watch('^lib/(.*)\.rb')             { |m| run_spec_matching(m[1]) }
watch('^spec/spec_helper\.rb')     { run_all_specs }
watch('^spec/support/.*\.rb')      { run_all_specs }

# --------------------------------------------------
# Signal Handling
# --------------------------------------------------

# Ctrl-\
Signal.trap('QUIT') { run_all_specs }
# Ctrl-C
Signal.trap('INT')  { abort("\n") }
