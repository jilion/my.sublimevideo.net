require 'spec_helper'

describe AddonsController do

  it { put(with_subdomain('my', 'sites/1/addons/update_all')).should route_to('addons#update_all', site_id: '1') }

end
