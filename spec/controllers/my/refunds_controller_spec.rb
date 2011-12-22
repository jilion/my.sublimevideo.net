require 'spec_helper'

describe My::RefundsController do

  it_should_behave_like "redirect when connected as", 'http://my.test.host/login', [:guest], { get: :index, post: :create }

end
