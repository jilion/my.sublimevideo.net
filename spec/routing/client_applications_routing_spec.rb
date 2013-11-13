require 'spec_helper'

describe ClientApplicationsController do

  it { expect(get(with_subdomain('my', 'account/applications'))).to         route_to('client_applications#index') }
  it { expect(get(with_subdomain('my', 'account/applications/new'))).to     route_to('client_applications#new') }
  it { expect(get(with_subdomain('my', 'account/applications/1/edit'))).to  route_to('client_applications#edit', id: '1') }
  it { expect(post(with_subdomain('my', 'account/applications'))).to        route_to('client_applications#create') }
  it { expect(put(with_subdomain('my', 'account/applications/1'))).to       route_to('client_applications#update', id: '1') }
  it { expect(delete(with_subdomain('my', 'account/applications/1'))).to    route_to('client_applications#destroy', id: '1') }

end
