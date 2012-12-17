require 'spec_helper'

describe KitsController do

  it { get(with_subdomain('my', 'sites/1/players/2/edit')).should route_to('kits#edit', site_id: '1', id: '2') }
  it { put(with_subdomain('my', 'sites/1/players/2')).should route_to('kits#update', site_id: '1', id: '2') }

end
