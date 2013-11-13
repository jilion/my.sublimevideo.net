require 'spec_helper'

describe AddonsController do

  it { expect(get(with_subdomain('my', '/addons'))).to route_to('addons#index') }
  it { expect(get(with_subdomain('my', '/sites/1/addons'))).to route_to('addons#index', site_id: '1') }

  it { expect(get(with_subdomain('my', '/addons/logo'))).to route_to('addons#show', id: 'logo') }
  it { expect(get(with_subdomain('my', '/sites/1/addons/logo'))).to route_to('addons#show', site_id: '1', id: 'logo') }

  it { expect(put(with_subdomain('my', '/sites/1/addons/subscribe'))).to route_to('addons#subscribe', site_id: '1') }

end
