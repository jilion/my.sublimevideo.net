class Voxcast < RequestLogAnalyzer::FileFormat::Base
  
  # Define line types
  line_definition :default do |line|
    line.header = true
    line.footer = true
    
    line.regexp = /^(.*)\s(.*)\s(.*)\s(.*\s.*)\s"(.*)"\s([0-9]+)\s([0-9]+)\s"(.*)"\s"(.*)"\s$/
    
    line.capture(:ip)
    line.capture(:todo2)
    line.capture(:todo3)
    line.capture(:todo4)
    line.capture(:todo5)
    line.capture(:todo6)
    line.capture(:todo7)
    line.capture(:file)
    line.capture(:user_agent)
  end
  
  # define the summary report
  report do |analyze|
    analyze.frequency :file, :title => "Hit", :line_type => :default
  end
  
end
