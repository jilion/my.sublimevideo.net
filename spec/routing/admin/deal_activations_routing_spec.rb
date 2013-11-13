require 'spec_helper'

describe Admin::DealActivationsController do

  it { expect(get(with_subdomain('admin', 'deals/activations'))).to route_to('admin/deal_activations#index') }

end
