require 'rspec/core/formatters/base_formatter'
require 'growl'

class GrowlFormatter < RSpec::Core::Formatters::ProgressFormatter
  
  def dump_summary
    super
    failure_count = failed_examples.size
    pending_count = pending_examples.size
    
    icon = if failure_count > 0
      'failed'
    elsif pending_count > 0
      'pending'
    else
      'success'
    end
    
    # image_path = File.dirname(__FILE__) + "/../images/#{icon}.png"
    message = "#{@example_count} examples, #{failure_count} failures"
    if pending_count > 0
      message << " (#{pending_count} pending)"
    end
    message << "\nin #{format_seconds(duration)} seconds"
    
    Growl.notify message, :title => "RSpec results", :icon => image_path(icon)
  end
  
private
  
  # failed | pending | success
  def image_path(icon)
    File.expand_path File.dirname(__FILE__) + "/images/#{icon}.png"
  end
  
end