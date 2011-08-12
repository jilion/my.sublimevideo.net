require 'spec_helper'

describe Admin::ReleasesController do

  it { { get:  'admin/releases' }.should   route_to(controller: 'admin/releases', action: 'index') }
  it { { post: 'admin/releases' }.should   route_to(controller: 'admin/releases', action: 'create') }
  it { { put:  'admin/releases/1' }.should route_to(controller: 'admin/releases', action: 'update', id: '1') }

end
