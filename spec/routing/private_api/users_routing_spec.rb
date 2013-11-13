require 'spec_helper'

describe PrivateApi::UsersController do

  it { expect(get(with_subdomain('my', 'private_api/users/1'))).to       route_to('private_api/users#show', id: '1') }

end
