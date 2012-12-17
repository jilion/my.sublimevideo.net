require 'spec_helper'

describe ClientApplicationsController do

  it { get(with_subdomain('my', 'account/applications')).should         route_to('client_applications#index') }
  it { get(with_subdomain('my', 'account/applications/new')).should     route_to('client_applications#new') }
  it { get(with_subdomain('my', 'account/applications/1/edit')).should  route_to('client_applications#edit', id: '1') }
  it { post(with_subdomain('my', 'account/applications')).should        route_to('client_applications#create') }
  it { put(with_subdomain('my', 'account/applications/1')).should       route_to('client_applications#update', id: '1') }
  it { delete(with_subdomain('my', 'account/applications/1')).should    route_to('client_applications#destroy', id: '1') }

end
