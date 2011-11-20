require 'spec_helper'

describe My::Users::SessionsController do

  it { get('?p=login').should  route_to('com/pages#show', page: 'home') }
  it { get('gs-login').should  route_to('my/users/sessions#new_gs') }
  it { post('gs-login').should route_to('my/users/sessions#create_gs') }
  it { post('login').should    route_to('my/users/sessions#create') }

end
