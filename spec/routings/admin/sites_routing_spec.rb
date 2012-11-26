require 'spec_helper'

describe Admin::SitesController do

  it { get(with_subdomain('admin', 'sites')).should           route_to('admin/sites#index') }
  it { get(with_subdomain('admin', 'sites/1/edit')).should    route_to('admin/sites#edit', id: '1') }
  it { put(with_subdomain('admin', 'sites/1')).should         route_to('admin/sites#update', id: '1') }
  it { put(with_subdomain('admin', 'sites/1/update_app_design_subscription')).should route_to('admin/sites#update_app_design_subscription', id: '1') }
  it { put(with_subdomain('admin', 'sites/1/update_addon_plan_subscription')).should route_to('admin/sites#update_addon_plan_subscription', id: '1') }

end
