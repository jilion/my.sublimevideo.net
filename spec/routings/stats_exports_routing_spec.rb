require 'spec_helper'

describe StatsExportsController do

  it { get(with_subdomain('my', 'stats/exports/token')).should  route_to('stats_exports#show', id: 'token') }
  it { post(with_subdomain('my', 'stats/exports')).should       route_to('stats_exports#create') }

end
