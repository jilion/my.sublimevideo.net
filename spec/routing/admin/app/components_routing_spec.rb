require 'spec_helper'

describe Admin::App::ComponentsController do

  it { expect(get(with_subdomain('admin', 'app/components'))).to   route_to('admin/app/components#index') }
  it { expect(post(with_subdomain('admin', 'app/components'))).to  route_to('admin/app/components#create') }
  it { expect(get(with_subdomain('admin', 'app/components/1'))).to route_to('admin/app/components#show',   id: '1') }
  it { expect(put(with_subdomain('admin', 'app/components/1'))).to route_to('admin/app/components#update', id: '1') }
  it { expect(delete(with_subdomain('admin', 'app/components/1'))).to route_to('admin/app/components#destroy', id: '1') }

end
