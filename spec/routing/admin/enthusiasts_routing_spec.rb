require 'spec_helper'

describe Admin::EnthusiastsController do

  it { get(with_subdomain('admin', 'enthusiasts')).should route_to('admin/enthusiasts#index') }
  it { get(with_subdomain('admin', 'enthusiasts/1')).should route_to('admin/enthusiasts#show', id: '1') }

end
