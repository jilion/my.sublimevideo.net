require 'spec_helper'

describe Admin::EnthusiastsController do

  it { expect(get(with_subdomain('admin', 'enthusiasts'))).to route_to('admin/enthusiasts#index') }
  it { expect(get(with_subdomain('admin', 'enthusiasts/1'))).to route_to('admin/enthusiasts#show', id: '1') }

end
