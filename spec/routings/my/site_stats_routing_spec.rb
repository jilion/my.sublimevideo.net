require 'spec_helper'

describe My::SiteStatsController do

  it { get(with_subdomain('my', 'sites/1/stats')).should route_to('my/site_stats#index', site_id: '1') }
  it { put(with_subdomain('my', 'sites/1/stats/trial')).should route_to('my/site_stats#trial', site_id: '1') }

end
