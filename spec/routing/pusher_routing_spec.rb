require 'spec_helper'

describe PusherController do

  it { expect(post(with_subdomain('my', 'pusher/auth'))).to route_to('pusher#auth') }
  it { expect(post(with_subdomain('my', 'pusher/webhook'))).to route_to('pusher#webhook') }

end
