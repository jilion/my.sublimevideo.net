require 'spec_helper'

describe Admin::TweetsController do

  it { { get: 'admin/tweets' }.should            route_to(controller: 'admin/tweets', action: 'index') }
  it { { put: 'admin/tweets/1/favorite' }.should route_to(controller: 'admin/tweets', action: 'favorite', id: '1') }

end
