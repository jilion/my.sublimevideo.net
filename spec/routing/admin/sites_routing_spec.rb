require 'spec_helper'

describe Admin::SitesController do

  it { expect(get(with_subdomain('admin', 'sites'))).to           route_to('admin/sites#index') }
  it { expect(get(with_subdomain('admin', 'sites/1/edit'))).to    route_to('admin/sites#edit', id: '1') }
  it { expect(patch(with_subdomain('admin', 'sites/1'))).to         route_to('admin/sites#update', id: '1') }
  it { expect(patch(with_subdomain('admin', 'sites/1/update_design_subscription'))).to route_to('admin/sites#update_design_subscription', id: '1') }
  it { expect(patch(with_subdomain('admin', 'sites/1/update_addon_plan_subscription'))).to route_to('admin/sites#update_addon_plan_subscription', id: '1') }

end
