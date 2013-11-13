require 'spec_helper'

describe OauthController do

  it { expect(get(with_subdomain('my', 'oauth/authorize'))).to route_to('oauth#authorize') }
  it { expect(post(with_subdomain('my', 'oauth/authorize'))).to route_to('oauth#authorize') }
  it { expect(delete(with_subdomain('my', 'oauth/revoke'))).to route_to('oauth#revoke') }

  # OAuth 2
  it { expect(post(with_subdomain('my', 'oauth/access_token'))).to route_to('oauth#token') }

end
