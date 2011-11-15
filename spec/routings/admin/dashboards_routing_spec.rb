require 'spec_helper'

describe Admin::DashboardsController do

  it { get(with_subdomain('admin', 'dashboard')).should route_to('admin/dashboards#show') }

end
