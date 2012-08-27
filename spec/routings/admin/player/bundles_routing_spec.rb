require 'spec_helper'

describe Admin::Player::BundleVersionsController do

  it { get(with_subdomain('admin', 'player/bundles/e/versions')).should route_to('admin/player/bundle_versions#index', bundle_id: 'e') }
  it { get(with_subdomain('admin', 'player/bundles/e/versions/1')).should route_to('admin/player/bundle_versions#show', bundle_id: 'e',  id: '1') }
  it { post(with_subdomain('admin', 'player/bundles/e/versions')).should route_to('admin/player/bundle_versions#create', bundle_id: 'e') }
  it { delete(with_subdomain('admin', 'player/bundles/e/versions/1')).should route_to('admin/player/bundle_versions#destroy', bundle_id: 'e', id: '1') }

end
