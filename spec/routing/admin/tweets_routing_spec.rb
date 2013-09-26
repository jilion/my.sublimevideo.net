require 'spec_helper'

describe Admin::TweetsController do

  it { get(with_subdomain('admin', 'tweets')).should            route_to('admin/tweets#index') }
  it { patch(with_subdomain('admin', 'tweets/1/favorite')).should route_to('admin/tweets#favorite', id: '1') }

end
