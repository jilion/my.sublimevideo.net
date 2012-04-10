require 'spec_helper'

describe Users::SessionsController do

  it { post(with_subdomain('my', 'login')).should    route_to('users/sessions#create') }

  it { get(with_subdomain('my', 'gs-login')).should  route_to('users/sessions#new_gs') }
  it { post(with_subdomain('my', 'gs-login')).should route_to('users/sessions#create_gs') }

end
