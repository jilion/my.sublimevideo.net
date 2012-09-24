def run(*cmd)
  system(*cmd)
  raise "Command #{cmd.inspect} failed!" unless $?.success?
end

def timed(&block)
  if block_given?
    start_time = Time.now.utc
    yield
    print "\tDone in #{Time.now.utc - start_time}s!\n\n"
  else
    print "\n\nYou must pass a block to this method!\n\n"
  end
end

