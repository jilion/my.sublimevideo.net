require 'spec_helper'

describe PrivateApi::SitesController do

  it { expect(get(with_subdomain('my', 'private_api/sites'))).to           route_to('private_api/sites#index') }
  it { expect(get(with_subdomain('my', 'private_api/sites/tokens'))).to    route_to('private_api/sites#tokens') }
  it { expect(get(with_subdomain('my', 'private_api/sites/1'))).to         route_to('private_api/sites#show', id: '1') }
  it { expect(put(with_subdomain('my', 'private_api/sites/1/add_tag'))).to route_to('private_api/sites#add_tag', id: '1') }

end
