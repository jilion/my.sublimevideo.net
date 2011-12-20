require 'spec_helper'

describe My::TicketsController do

  it_should_behave_like "redirect when connected as", 'http://my.test.host/login', [:guest], { post: :create }

end
