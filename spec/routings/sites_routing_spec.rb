require 'spec_helper'

describe SitesController do

  it { get(with_subdomain('my', 'sites')).should         route_to('sites#index') }
  it { get(with_subdomain('my', 'sites/new')).should     route_to('sites#new') }
  it { get(with_subdomain('my', 'sites/1/edit')).should  route_to('sites#edit', id: '1') }
  it { post(with_subdomain('my', 'sites')).should        route_to('sites#create') }
  it { put(with_subdomain('my', 'sites/1')).should       route_to('sites#update', id: '1') }
  it { delete(with_subdomain('my', 'sites/1')).should    route_to('sites#destroy', id: '1') }

end
