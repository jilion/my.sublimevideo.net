require 'spec_helper'

describe My::SitesController do

  it { get(with_subdomain('my', 'sites')).should         route_to('my/sites#index') }
  it { get(with_subdomain('my', 'sites/new')).should     route_to('my/sites#new') }
  it { get(with_subdomain('my', 'sites/1/edit')).should  route_to('my/sites#edit', id: '1') }
  it { post(with_subdomain('my', 'sites')).should        route_to('my/sites#create') }
  it { put(with_subdomain('my', 'sites/1')).should       route_to('my/sites#update', id: '1') }
  it { delete(with_subdomain('my', 'sites/1')).should    route_to('my/sites#destroy', id: '1') }
  it { get(with_subdomain('my', 'sites/1/state')).should route_to('my/sites#state', id: '1') }

end
