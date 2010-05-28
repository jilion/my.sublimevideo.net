require 'exceptional'

# If old plugin still installed then we don't want to install this one.
# In production environments we should continue to work as before, but in development/test we should
# advise how to correct the problem and exit
if (defined?(Exceptional::VERSION::STRING) rescue nil) && %w(development test).include?(RAILS_ENV)
  message = %Q(
  ***********************************************************************
  You seem to still have an old version of the Exceptional plugin installed.
  Remove it from /vendor/plugins and try again.
  ***********************************************************************
  )
  puts message
  exit -1
else
  begin
    Exceptional::Config.load(File.join(Rails.root, "/config/exceptional.yml"))

    Exceptional.logger.info("Loading Exceptional for #{Rails::VERSION::STRING}")

    if Rails::VERSION::STRING.to_i > 2 
      puts "Exceptional Rails 3 Support via Rack"
      ::Rails.configuration.middleware.insert_after 'ActionDispatch::ShowExceptions', Rack::RailsExceptional      
    else    
      require File.join('exceptional', 'integration', 'rails')
      require File.join('exceptional', 'integration', 'dj')
    end
  rescue => e
    STDERR.puts "Problem starting Exceptional Plugin. Your app will run as normal."
    Exceptional.logger.error(e.message)
    Exceptional.logger.error(e.backtrace)
  end
end
