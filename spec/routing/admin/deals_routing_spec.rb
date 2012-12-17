require 'spec_helper'

describe Admin::DealsController do

  it { get(with_subdomain('admin', 'deals')).should route_to('admin/deals#index') }

end
