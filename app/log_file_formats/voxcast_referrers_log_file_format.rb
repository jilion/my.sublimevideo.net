# http://cdn.sublimevideo.net/_.gif?t=ibvjcopp&i=1310389131519&h=m&e=l&vn=1
class VoxcastReferrersLogFileFormat < RequestLogAnalyzer::FileFormat::Base
  extend VoxcastLogFileFormat

  def self.report_trackers
    report_trackers_for(:referrer)
  end

end
