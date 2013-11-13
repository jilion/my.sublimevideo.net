require 'spec_helper'

describe UsersController do

  it { expect(get(with_subdomain('my', 'signup'))).to  route_to('users#new') }
  it { expect(post(with_subdomain('my', 'signup'))).to route_to('users#create') }

  it { expect(get(with_subdomain('my', 'account'))).to           route_to('users#edit') }
  it { expect(get(with_subdomain('my', 'account/more-info'))).to route_to('users#more_info') }
  it { expect(put(with_subdomain('my', 'account'))).to           route_to('users#update') }

  it { expect(post(with_subdomain('my', 'login'))).to route_to('users/sessions#create') }
  it { expect(get(with_subdomain('my', 'logout'))).to route_to('users/sessions#destroy') }

  it { expect(get(with_subdomain('my', 'confirmation'))).to     route_to('users/confirmations#show') }
  it { expect(get(with_subdomain('my', 'confirmation/new'))).to route_to('users/confirmations#new') }
  it { expect(post(with_subdomain('my', 'confirmation'))).to    route_to('users/confirmations#create') }

  it { expect(delete(with_subdomain('my', 'notice/1'))).to route_to('users#hide_notice', id: '1') }

end
