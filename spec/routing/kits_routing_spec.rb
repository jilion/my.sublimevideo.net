require 'spec_helper'

describe KitsController do

  it { expect(get(with_subdomain('my', 'sites/1/players/2/edit'))).to route_to('kits#edit', site_id: '1', id: '2') }
  it { expect(put(with_subdomain('my', 'sites/1/players/2'))).to route_to('kits#update', site_id: '1', id: '2') }

end
