require 'spec_helper'

describe Admin::SitesController do

  it { { get: 'admin/sites' }.should           route_to(controller: 'admin/sites', action: 'index') }
  it { { get: 'admin/sites/1/edit' }.should    route_to(controller: 'admin/sites', action: 'edit', id: '1') }
  it { { put: 'admin/sites/1' }.should         route_to(controller: 'admin/sites', action: 'update', id: '1') }
  it { { put: 'admin/sites/1/sponsor' }.should route_to(controller: 'admin/sites', action: 'sponsor', id: '1') }

end
