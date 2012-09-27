require 'spec_helper'

describe Admin::Player::ComponentsController do

  it { get(with_subdomain('admin', 'player/components')).should   route_to('admin/player/components#index') }
  it { post(with_subdomain('admin', 'player/components')).should  route_to('admin/player/components#create') }
  it { get(with_subdomain('admin', 'player/components/1')).should route_to('admin/player/components#show',   id: '1') }
  it { put(with_subdomain('admin', 'player/components/1')).should route_to('admin/player/components#update', id: '1') }
  it { delete(with_subdomain('admin', 'player/components/1')).should route_to('admin/player/components#destroy', id: '1') }

end
