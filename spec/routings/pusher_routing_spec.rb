require 'spec_helper'

describe PusherController do

  it { post(with_subdomain('my', 'pusher/auth')).should route_to('pusher#auth') }

end
