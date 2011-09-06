require 'spec_helper'

describe PusherController do

  it { { post: '/pusher/auth' }.should route_to(controller: 'pusher', action: 'auth') }

end
