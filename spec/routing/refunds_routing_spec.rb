require 'spec_helper'

describe RefundsController do

  it { { get:  'refund' }.should route_to(controller: 'refunds', action: 'index') }
  it { { post: 'refund' }.should route_to(controller: 'refunds', action: 'create') }

end
