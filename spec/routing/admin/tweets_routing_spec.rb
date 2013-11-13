require 'spec_helper'

describe Admin::TweetsController do

  it { expect(get(with_subdomain('admin', 'tweets'))).to            route_to('admin/tweets#index') }
  it { expect(patch(with_subdomain('admin', 'tweets/1/favorite'))).to route_to('admin/tweets#favorite', id: '1') }

end
