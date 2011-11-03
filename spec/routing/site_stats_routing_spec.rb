require 'spec_helper'

describe SiteStatsController do

  it { { get: 'sites/1/stats' }.should route_to(controller: 'site_stats', site_id: '1', action: 'index') }
  it { { put: 'sites/1/stats/trial' }.should route_to(controller: 'site_stats', site_id: '1', action: 'trial') }

end
