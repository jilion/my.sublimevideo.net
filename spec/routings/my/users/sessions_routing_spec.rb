require 'spec_helper'

describe My::Users::SessionsController do

  it { get(with_subdomain('www', '?p=login')).should route_to('www/pages#show', page: 'home', format: :html) }
  it { post(with_subdomain('my', 'login')).should    route_to('my/users/sessions#create') }

  it { get(with_subdomain('my', 'gs-login')).should  route_to('my/users/sessions#new_gs') }
  it { post(with_subdomain('my', 'gs-login')).should route_to('my/users/sessions#create_gs') }

end
