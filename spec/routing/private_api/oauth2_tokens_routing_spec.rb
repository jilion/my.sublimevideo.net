require 'spec_helper'

describe PrivateApi::Oauth2TokensController do

  it { get(with_subdomain('my', 'private_api/oauth2_tokens/1')).should route_to('private_api/oauth2_tokens#show', id: '1') }

end
