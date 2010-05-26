require 'spec_helper'

describe LogAnalyzer do
  
  it "should parse and return trackers" do
    logs_file = File.new(Rails.root.join('spec/fixtures/cdn.sublimevideo.net.log.1274798340-1274798400.gz'))
    trackers = LogAnalyzer.parse(logs_file)
    tracker = trackers.select { |tracker| tracker.options[:title] == :license }.first
    tracker.categories.should == { "/js/12345678.js" => 9 }
  end
  
end