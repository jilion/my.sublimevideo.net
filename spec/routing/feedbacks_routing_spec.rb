require 'spec_helper'

describe FeedbacksController do

  it { expect(get(with_subdomain('my', 'feedback'))).to  route_to('feedbacks#new') }
  it { expect(post(with_subdomain('my', 'feedback'))).to route_to('feedbacks#create') }

end
