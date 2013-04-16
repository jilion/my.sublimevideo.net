require 'spec_helper'

describe AddonsController do

  it { get(with_subdomain('my', '/addons')).should route_to('addons#index') }
  it { get(with_subdomain('my', '/sites/1/addons')).should route_to('addons#index', site_id: '1') }

  it { get(with_subdomain('my', '/addons/logo')).should route_to('addons#show', id: 'logo') }
  it { get(with_subdomain('my', '/sites/1/addons/logo')).should route_to('addons#show', site_id: '1', id: 'logo') }

  it { put(with_subdomain('my', '/sites/1/addons/subscribe')).should route_to('addons#subscribe', site_id: '1') }

end
