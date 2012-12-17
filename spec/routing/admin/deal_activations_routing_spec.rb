require 'spec_helper'

describe Admin::DealActivationsController do

  it { get(with_subdomain('admin', 'deals/activations')).should route_to('admin/deal_activations#index') }

end
