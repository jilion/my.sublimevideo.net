require 'spec_helper'

describe SitesController do

  it { { get:    'sites' }.should         route_to(controller: 'sites', action: 'index') }
  it { { get:    'sites/new' }.should     route_to(controller: 'sites', action: 'new') }
  it { { get:    'sites/1/edit' }.should  route_to(controller: 'sites', action: 'edit', id: '1') }
  it { { post:   'sites' }.should         route_to(controller: 'sites', action: 'create') }
  it { { put:    'sites/1' }.should       route_to(controller: 'sites', action: 'update', id: '1') }
  it { { delete: 'sites/1' }.should       route_to(controller: 'sites', action: 'destroy', id: '1') }
  it { { get:    'sites/1/state' }.should route_to(controller: 'sites', action: 'state', id: '1') }

end
