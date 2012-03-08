require 'spec_helper'

describe Admin::DealsController do

  it_should_behave_like "redirect when connected as", 'http://admin.test.host/login', [:user, :guest], { get: :index }

end