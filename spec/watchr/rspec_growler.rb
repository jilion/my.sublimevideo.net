# require 'rspec/core/runner/formatter/base_formatter'
require "rspec/runner/formatter/base_formatter"

class RSpecGrowler < Spec::Runner::Formatter::BaseFormatter
  
  def dump_summary(duration, total, failures, pending)
    p duration
    p total
    p failures
    p pending
    
    icon = if failures > 0
      'failed'
    elsif pending > 0
      'pending'
    else
      'success'
    end
    
    # image_path = File.dirname(__FILE__) + "/../images/#{icon}.png"
    message = "#{total} examples, #{failures} failures"
    if pending > 0
      message << " (#{pending} pending)"
    end
    
    notify "Spec Results", message, icon
    
  end
  
  def notify(title, msg, icon, pri = 0)
    system("growlnotify -w -n watchr --image #{image_path(icon)} -p #{pri} -m #{msg.inspect} #{title} &") 
  end
    
  # failed | pending | success
  def image_path(icon)
    File.expand_path File.dirname(__FILE__) + "/../../images/#{icon}.png"
  end
end