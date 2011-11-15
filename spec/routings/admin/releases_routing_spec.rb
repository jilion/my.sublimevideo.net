require 'spec_helper'

describe Admin::ReleasesController do

  it { get(with_subdomain('admin', 'releases')).should   route_to('admin/releases#index') }
  it { post(with_subdomain('admin', 'releases')).should  route_to('admin/releases#create') }
  it { put(with_subdomain('admin', 'releases/1')).should route_to('admin/releases#update', id: '1') }

end
