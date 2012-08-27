require 'spec_helper'

describe Admin::Player::BundlesController do

  it { get(with_subdomain('admin', 'player/bundles')).should   route_to('admin/player/bundles#index') }
  it { post(with_subdomain('admin', 'player/bundles')).should  route_to('admin/player/bundles#create') }
  it { get(with_subdomain('admin', 'player/bundles/1')).should route_to('admin/player/bundles#show',   id: '1') }
  it { put(with_subdomain('admin', 'player/bundles/1')).should route_to('admin/player/bundles#update', id: '1') }
  it { delete(with_subdomain('admin', 'player/bundles/1')).should route_to('admin/player/bundles#destroy', id: '1') }

end
