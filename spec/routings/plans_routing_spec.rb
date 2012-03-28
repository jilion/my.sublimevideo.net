require 'spec_helper'

describe PlansController do

  it { get(with_subdomain('my', 'sites/1/plan/edit')).should route_to('plans#edit', site_id: '1') }
  it { put(with_subdomain('my', 'sites/1/plan')).should      route_to('plans#update', site_id: '1') }
  it { delete(with_subdomain('my', 'sites/1/plan')).should   route_to('plans#destroy', site_id: '1') }

end
