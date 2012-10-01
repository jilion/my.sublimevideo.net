require 'spec_helper'

describe Admin::PlansController do

  it { get(with_subdomain('admin', 'plans')).should  route_to('admin/plans#index') }

end
