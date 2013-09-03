class VoxcastUserAgentsLogFileFormat < RequestLogAnalyzer::FileFormat::Base
  extend VoxcastLogFileFormat

  def self.report_trackers
    report_trackers_for(:useragent)
  end

end
