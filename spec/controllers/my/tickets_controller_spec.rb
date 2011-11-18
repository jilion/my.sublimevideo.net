require 'spec_helper'

describe My::TicketsController do

  it_should_behave_like "redirect when connected as", 'http://test.host/', [:guest], { post: :create }

end
