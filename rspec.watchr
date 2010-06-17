# Run me with:
#
# $ watchr rspec.watchr

# --------------------------------------------------
# Convenience Methods
# --------------------------------------------------

def all_spec_files
  Dir['spec/**/*_spec.rb']
end

def run_spec_matching(thing_to_match)
  puts thing_to_match
  matches = all_spec_files.grep(/#{thing_to_match}_spec/i)
  if matches.empty?
    puts "Sorry, thanks for playing, but there were no matches for #{thing_to_match}"
  else
    run matches.join(' ')
  end
end

def run(files_to_run, options = {})
  # system("clear")
  puts(options[:message] || "Running: #{files_to_run}")
  system "rspec -c -r spec/watchr/growl_formatter.rb -f GrowlFormatter #{files_to_run}"
end

def run_all_specs
  run(all_spec_files.join(' '), :message => " --- Running all specs --- ")
end

# --------------------------------------------------
# Watchr Rules
# --------------------------------------------------

watch('^app/controllers/(.*)\.rb')      { |m| run_spec_matching("controllers/#{m[1]}") }
watch('^app/models/(.*)\.rb')           { |m| run_spec_matching("models/#{m[1]}") }
watch('^lib/(.*)\.rb')                  { |m| run_spec_matching("lib/#{m[1]}") }
watch('^lib/logs_file_format/(.*)\.rb') { |m| run_spec_matching("lib/log_analyzer_spec.rb") }
watch('^spec/(.*)_spec\.rb')            { |m| run_spec_matching(m[1]) }
watch('^spec/spec_helper\.rb')          { run_all_specs }
watch('^spec/support/.*\.rb')           { run_all_specs }

# --------------------------------------------------
# Signal Handling
# --------------------------------------------------

# Ctrl-\
Signal.trap('QUIT') { run_all_specs }
# Ctrl-C
Signal.trap('INT')  { abort("\n") }
# Ctrl-Z
Signal.trap('TSTP') { reload_spork }

# --------------------------------------------------
# Spork
# --------------------------------------------------

def reload_spork
  puts "(Re)loading spork..."
  system("kill $(ps aux | awk '/spork/&&!/awk/{print $2;}') >/dev/null 2>&1")
  system("bundle exec spork >/dev/null 2>&1 < /dev/null &")
  wait_for(8989)
  puts "done."
end

def wait_for(port)
  15.times do
    begin
      TCPSocket.new('localhost', 8989).close
    rescue Errno::ECONNREFUSED
      sleep(1)
      next
    end
    return true
  end
  raise "could not load spork; make sure you can use it manually first"
end