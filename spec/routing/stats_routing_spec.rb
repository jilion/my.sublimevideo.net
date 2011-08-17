require 'spec_helper'

describe StatsController do

  it { { get: 'sites/1/stats' }.should route_to(controller: 'stats', site_id: '1', action: 'index') }

end
