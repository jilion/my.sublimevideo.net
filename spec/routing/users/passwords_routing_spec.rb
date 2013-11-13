require 'spec_helper'

describe Devise::PasswordsController do

  it { expect(get(with_subdomain('my', 'password/new'))).to  route_to('devise/passwords#new') }
  it { expect(post(with_subdomain('my', 'password'))).to     route_to('devise/passwords#create') }
  it { expect(get(with_subdomain('my', 'password/edit'))).to route_to('devise/passwords#edit') }
  it { expect(put(with_subdomain('my', 'password'))).to      route_to('devise/passwords#update') }

end
