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

module LogsFileFormat
  class VoxcastVideoTags < RequestLogAnalyzer::FileFormat::Base
    extend LogsFileFormat::Voxcast

    def self.report_trackers
      analyze = RequestLogAnalyzer::Aggregator::Summarizer::Definer.new
      analyze.frequency(:video_tags, :title => :video_tags,
        :category => lambda { |r| remove_timestamp(r[:path_query]) },
        :if       => lambda { |r| gif_request?(r[:path_stem]) && countable_hit?(r) && good_token?(r[:path_query]) }
      )
      analyze.trackers
    end

  private

    def self.remove_timestamp(path_query)
      # removed timestamps
      path_query.gsub(/&i=[0-9]+/, '')
    end

    def self.gif_request?(path_stem)
      path_stem == "/_.gif"
    end

    def self.good_token?(path_query)
      path_query =~ /t=([a-z0-9]{8})/
    end

  end
end
