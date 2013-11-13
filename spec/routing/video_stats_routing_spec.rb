require 'spec_helper'

describe VideoStatsController do

  it { expect(get(with_subdomain('my', 'sites/1/videos/2/stats'))).to route_to('video_stats#index', site_id: '1', video_tag_id: '2') }

end
