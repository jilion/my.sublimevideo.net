require 'spec_helper'

describe My::RefundsController do

  it_should_behave_like "redirect when connected as", 'http://test.host/', [:guest], { get: :index, post: :create }

end
