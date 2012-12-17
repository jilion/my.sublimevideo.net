require 'spec_helper'

describe Admin::App::ComponentsController do

  it { get(with_subdomain('admin', 'app/components')).should   route_to('admin/app/components#index') }
  it { post(with_subdomain('admin', 'app/components')).should  route_to('admin/app/components#create') }
  it { get(with_subdomain('admin', 'app/components/1')).should route_to('admin/app/components#show',   id: '1') }
  it { put(with_subdomain('admin', 'app/components/1')).should route_to('admin/app/components#update', id: '1') }
  it { delete(with_subdomain('admin', 'app/components/1')).should route_to('admin/app/components#destroy', id: '1') }

end
