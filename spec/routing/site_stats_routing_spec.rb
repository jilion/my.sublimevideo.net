require 'spec_helper'

describe SiteStatsController do

  it { expect(get(with_subdomain('my', 'stats-demo'))).to route_to('site_stats#index', site_id: SiteToken[:www], demo: true) }
  it { expect(get(with_subdomain('my', 'sites/1/stats'))).to route_to('site_stats#index', site_id: '1') }
  it { expect(get(with_subdomain('my', 'sites/1/stats/videos'))).to route_to('site_stats#videos', site_id: '1') }

end
