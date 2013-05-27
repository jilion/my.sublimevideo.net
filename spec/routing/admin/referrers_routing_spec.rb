require 'spec_helper'

describe Admin::ReferrersController do

  it { get(with_subdomain('admin', 'referrers/pages')).should route_to('admin/referrers#pages') }

end
