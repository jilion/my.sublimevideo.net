require 'spec_helper'

describe SupportRequestsController do

  it_behaves_like "redirect when connected as", 'http://my.test.host/login', [:guest], { post: :create }

end
