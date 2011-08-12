require 'spec_helper'

describe Admin::DashboardsController do

  it { { get: 'admin/dashboard' }.should route_to(controller: 'admin/dashboards', action: 'show') }

end
