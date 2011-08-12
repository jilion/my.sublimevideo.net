require 'spec_helper'

describe Admin::PlansController do

  it { { get:  'admin/plans/new' }.should route_to(controller: 'admin/plans', action: 'new') }
  it { { get:  'admin/plans' }.should     route_to(controller: 'admin/plans', action: 'index') }
  it { { post: 'admin/plans' }.should     route_to(controller: 'admin/plans', action: 'create') }

end
