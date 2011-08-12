require 'spec_helper'

describe Admin::ReferrersController do

  it { { get: 'admin/referrers' }.should route_to(controller: 'admin/referrers', action: 'index') }

end
