require 'spec_helper'

describe PrivateApi::UsersController do

  it { get(with_subdomain('my', 'private_api/users/1')).should       route_to('private_api/users#show', id: '1') }
  it { get(with_subdomain('my', 'private_api/users/1/sites')).should route_to('private_api/sites#index', user_id: '1') }

end
