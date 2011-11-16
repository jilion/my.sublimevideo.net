require 'spec_helper'

describe My::UsersController do

  it { get(with_subdomain('my', 'signup')).should route_to('my/users/registrations#new') }
  it { post(with_subdomain('my', 'signup')).should route_to('my/users/registrations#create') }

  it { get(with_subdomain('my', 'account')).should             route_to('my/users/registrations#edit') }
  it { put(with_subdomain('my', 'account/credentials')).should route_to('my/users/registrations#update') }
  it { delete(with_subdomain('my', 'account')).should          route_to('my/users/registrations#destroy') }

  it { put(with_subdomain('my', 'account/info')).should route_to('my/users#update') }

  it { post(with_subdomain('my', 'login')).should route_to('my/users/sessions#create') }
  it { get(with_subdomain('my', 'logout')).should route_to('my/users/sessions#destroy') }

  it { get(with_subdomain('my', 'confirmation')).should     route_to('my/users/confirmations#show') }
  it { get(with_subdomain('my', 'confirmation/new')).should route_to('my/users/confirmations#new') }
  it { post(with_subdomain('my', 'confirmation')).should    route_to('my/users/confirmations#create') }

  it { put(with_subdomain('my', 'hide_notice/1')).should route_to('my/users#hide_notice', id: '1') }

end
