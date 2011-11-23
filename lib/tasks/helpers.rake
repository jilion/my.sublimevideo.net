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

def delete_all_files_in_public(path)
  if path.gsub('.', '') =~ /\w+/ # don't remove all files and directories in /public ! ;)
    print "Deleting all files and directories in /public/#{path}\n"
    timed do
      Dir["#{Rails.public_path}/#{path}/**/*"].each do |filename|
        File.delete(filename) if File.file?(filename)
      end
      Dir["#{Rails.public_path}/#{path}/**/*"].each do |filename|
        Dir.delete(filename) if File.directory?(filename)
      end
    end
  end
end

def disable_perform_deliveries(&block)
  if block_given?
    original_perform_deliveries = ActionMailer::Base.perform_deliveries
    # Disabling perform_deliveries (avoid to spam fakes email adresses)
    ActionMailer::Base.perform_deliveries = false

    yield

    # Switch back to the original perform_deliveries
    ActionMailer::Base.perform_deliveries = original_perform_deliveries
  else
    print "\n\nYou must pass a block to this method!\n\n"
  end
end
