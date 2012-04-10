require 'spec_helper'

describe UsersController do

  it { get(with_subdomain('my', 'signup')).should  route_to('users#new') }
  it { post(with_subdomain('my', 'signup')).should route_to('users#create') }

  it { get(with_subdomain('my', 'account')).should           route_to('users#edit') }
  it { get(with_subdomain('my', 'account/more-info')).should route_to('users#more_info') }
  it { put(with_subdomain('my', 'account')).should           route_to('users#update') }
  it { delete(with_subdomain('my', 'account')).should        route_to('users#destroy') }

  it { post(with_subdomain('my', 'login')).should route_to('users/sessions#create') }
  it { get(with_subdomain('my', 'logout')).should route_to('users/sessions#destroy') }

  it { get(with_subdomain('my', 'confirmation')).should     route_to('users/confirmations#show') }
  it { get(with_subdomain('my', 'confirmation/new')).should route_to('users/confirmations#new') }
  it { post(with_subdomain('my', 'confirmation')).should    route_to('users/confirmations#create') }

  it { delete(with_subdomain('my', 'notice/1')).should route_to('users#hide_notice', id: '1') }

end
