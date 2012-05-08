require 'spec_helper'

describe GoodbyeController do

  it { get(with_subdomain('my', 'goodbye')).should  route_to('goodbye#new') }
  it { post(with_subdomain('my', 'goodbye')).should route_to('goodbye#create') }

end
