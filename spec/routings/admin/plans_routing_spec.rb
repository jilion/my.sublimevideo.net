require 'spec_helper'

describe Admin::PlansController do

  it { get(with_subdomain('admin', 'plans/new')).should route_to('admin/plans#new') }
  it { get(with_subdomain('admin', 'plans')).should     route_to('admin/plans#index') }
  it { post(with_subdomain('admin', 'plans')).should    route_to('admin/plans#create') }

end
