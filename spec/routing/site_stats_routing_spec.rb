require 'spec_helper'

describe SiteStatsController do

  it { get(with_subdomain('my', 'stats-demo')).should route_to('site_stats#index', site_id: SiteToken[:www], demo: true) }
  it { get(with_subdomain('my', 'sites/1/stats')).should route_to('site_stats#index', site_id: '1') }
  it { get(with_subdomain('my', 'sites/1/stats/videos')).should route_to('site_stats#videos', site_id: '1') }

end
