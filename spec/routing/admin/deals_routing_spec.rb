require 'spec_helper'

describe Admin::DealsController do

  it { expect(get(with_subdomain('admin', 'deals'))).to route_to('admin/deals#index') }

end
