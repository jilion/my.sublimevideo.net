require 'spec_helper'

describe PrivateApi::SitesController do

  it { get(with_subdomain('my', 'private_api/sites')).should           route_to('private_api/sites#index') }
  it { get(with_subdomain('my', 'private_api/sites/tokens')).should    route_to('private_api/sites#tokens') }
  it { get(with_subdomain('my', 'private_api/sites/1')).should         route_to('private_api/sites#show', id: '1') }
  it { put(with_subdomain('my', 'private_api/sites/1/add_tag')).should route_to('private_api/sites#add_tag', id: '1') }

end
