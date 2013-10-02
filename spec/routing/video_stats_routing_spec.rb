require 'spec_helper'

describe VideoStatsController do

  it { get(with_subdomain('my', 'sites/1/videos/2/stats')).should route_to('video_stats#index', site_id: '1', video_tag_id: '2') }

end
