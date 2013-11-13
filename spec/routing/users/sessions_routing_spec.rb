require 'spec_helper'

describe Users::SessionsController do

  it { expect(post(with_subdomain('my', 'login'))).to    route_to('users/sessions#create') }

  it { expect(get(with_subdomain('my', 'gs-login'))).to  route_to('users/sessions#new_gs') }
  it { expect(post(with_subdomain('my', 'gs-login'))).to route_to('users/sessions#create_gs') }

end
