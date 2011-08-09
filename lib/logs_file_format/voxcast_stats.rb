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
  class VoxcastStats < RequestLogAnalyzer::FileFormat::Base
    extend LogsFileFormat::Voxcast

    def self.report_trackers
      analyze = RequestLogAnalyzer::Aggregator::Summarizer::Definer.new
      analyze.frequency(:stats, :title => :stats,
        :category => lambda { |r| [token_from(r[:path_query]), clean_query(r[:path_query]), r[:useragent]] },
        :if       => lambda { |r| gif_request?(r[:path_stem]) && countable_hit?(r) }
      )
      analyze.trackers
    end

  private

    def self.token_from(path_query)
      path_query.match(/t=([a-z0-9]{8})/).to_a.second
    end

    def self.clean_query(path_query)
      # removed timestamps & token (useless for parsing)
      path_query.gsub(/t=[a-z0-9]{8}|&i=[0-9]+/, '')
    end

    def self.gif_request?(path_stem)
      path_stem == "/_.gif"
    end

  end
end
