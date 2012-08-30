require 'spec_helper'

describe FeedbacksController do

  it { get(with_subdomain('my', 'feedback')).should  route_to('feedbacks#new') }
  it { post(with_subdomain('my', 'feedback')).should route_to('feedbacks#create') }

end
