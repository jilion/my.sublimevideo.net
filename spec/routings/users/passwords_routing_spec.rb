require 'spec_helper'

describe Users::PasswordsController do

  it { get(with_subdomain('my', 'password/new')).should       route_to('users/passwords#new') }
  it { post(with_subdomain('my', 'password')).should          route_to('users/passwords#create') }
  it { get(with_subdomain('my', 'password/edit')).should      route_to('users/passwords#edit') }
  it { put(with_subdomain('my', 'password')).should           route_to('users/passwords#update') }
  it { post(with_subdomain('my', 'password/validate')).should route_to('users/passwords#validate') }

end
