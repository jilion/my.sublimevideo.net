require 'spec_helper'

describe SitesController do

  it { expect(get(with_subdomain('my', 'sites'))).to         route_to('sites#index') }
  it { expect(get(with_subdomain('my', 'sites/1/edit'))).to  route_to('sites#edit', id: '1') }
  it { expect(put(with_subdomain('my', 'sites/1'))).to       route_to('sites#update', id: '1') }
  it { expect(delete(with_subdomain('my', 'sites/1'))).to    route_to('sites#destroy', id: '1') }

end
