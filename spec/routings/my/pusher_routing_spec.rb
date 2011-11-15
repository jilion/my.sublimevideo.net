require 'spec_helper'

describe My::PusherController do

  it { post(with_subdomain('my', 'pusher/auth')).should route_to('my/pusher#auth') }

end
