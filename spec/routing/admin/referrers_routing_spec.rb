require 'spec_helper'

describe Admin::ReferrersController do

  it { get(with_subdomain('admin', 'referrers')).should route_to('admin/referrers#index') }

end
