require 'spec_helper'

describe My::Users::PasswordsController do

  it { get(with_subdomain('my', 'password/new')).should       route_to('my/users/passwords#new') }
  it { post(with_subdomain('my', 'password')).should          route_to('my/users/passwords#create') }
  it { get(with_subdomain('my', 'password/edit')).should      route_to('my/users/passwords#edit') }
  it { put(with_subdomain('my', 'password')).should           route_to('my/users/passwords#update') }
  it { post(with_subdomain('my', 'password/validate')).should route_to('my/users/passwords#validate') }

end
