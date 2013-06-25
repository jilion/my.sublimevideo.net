require 'spec_helper'

describe Devise::PasswordsController do

  it { get(with_subdomain('my', 'password/new')).should  route_to('devise/passwords#new') }
  it { post(with_subdomain('my', 'password')).should     route_to('devise/passwords#create') }
  it { get(with_subdomain('my', 'password/edit')).should route_to('devise/passwords#edit') }
  it { put(with_subdomain('my', 'password')).should      route_to('devise/passwords#update') }

end
