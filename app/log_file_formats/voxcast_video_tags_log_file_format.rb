# encoding: utf-8

# var gif = new Image();
#
# gif.src = "http://cdn.sublimevideo.net/_.gif?t=ibvjcopp&i=1310389131519&h=m&e=l&vn=1";
# gif.src = "http://cdn.sublimevideo.net/_.gif?t=12345678&i=1310389131512&h=e&e=l&vn=2";
# gif.src =     "https://4076.voxcdn.com/_.gif?t=ibvjcopp&i=1310389131519&h=i&e=l&vn=1";
#
# gif.src = "http://cdn.sublimevideo.net/_.gif?t=ibvjcopp&i=1310389131519&h=m&e=p&pd=d&pm=h";
# gif.src = "http://cdn.sublimevideo.net/_.gif?t=12345678&i=1310389131519&h=e&e=p&pd=m&pm=h";
# gif.src = "http://cdn.sublimevideo.net/_.gif?t=12345678&i=1310389131512&h=d&e=p&pd=d&pm=f";
# gif.src =     "https://4076.voxcdn.com/_.gif?t=ibvjcopp&i=1310389131519&h=m&e=p&pd=t&pm=h";
#
# gif.src = "http://cdn.sublimevideo.net/_.gif?t=ibvjcopp&i=1310389131519&h=m&e=s&pd=d&pm=h";
# gif.src = "http://cdn.sublimevideo.net/_.gif?t=12345678&i=1310389131512&h=d&e=s&pd=d&pm=f";
# gif.src =     "https://4076.voxcdn.com/_.gif?t=ibvjcopp&i=1310389131519&h=m&e=s&pd=t&pm=h";

class VoxcastVideoTagsLogFileFormat < RequestLogAnalyzer::FileFormat::Base
  extend VoxcastLogFileFormat

  def self.report_trackers
    analyze = RequestLogAnalyzer::Aggregator::Summarizer::Definer.new
    analyze.frequency(:video_tags, title: :video_tags,
      category: ->(r) { remove_timestamp(r) },
      if: ->(r) { countable_hit?(r) && gif_request?(r) && good_token?(r) }
    )
    analyze.trackers
  end

end
