require 'spec_helper'

describe PlansController do

  it { { get:    'sites/1/plan/edit' }.should route_to(controller: 'plans', action: 'edit', site_id: '1') }
  it { { put:    'sites/1/plan' }.should      route_to(controller: 'plans', action: 'update', site_id: '1') }
  it { { delete: 'sites/1/plan' }.should      route_to(controller: 'plans', action: 'destroy', site_id: '1') }

end
