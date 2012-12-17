require 'spec_helper'

describe OauthController do

  it { get(with_subdomain('my', 'oauth/authorize')).should route_to('oauth#authorize') }
  it { post(with_subdomain('my', 'oauth/authorize')).should route_to('oauth#authorize') }
  it { delete(with_subdomain('my', 'oauth/revoke')).should route_to('oauth#revoke') }

  # OAuth 2
  it { post(with_subdomain('my', 'oauth/access_token')).should route_to('oauth#token') }

end
