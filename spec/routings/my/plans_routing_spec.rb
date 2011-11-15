require 'spec_helper'

describe My::PlansController do

  it { get(with_subdomain('my', 'sites/1/plan/edit')).should route_to('my/plans#edit', site_id: '1') }
  it { put(with_subdomain('my', 'sites/1/plan')).should      route_to('my/plans#update', site_id: '1') }
  it { delete(with_subdomain('my', 'sites/1/plan')).should   route_to('my/plans#destroy', site_id: '1') }

end
