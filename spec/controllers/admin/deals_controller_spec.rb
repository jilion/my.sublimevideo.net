require 'spec_helper'

describe Admin::DealsController do

  it_behaves_like "redirect when connected as", 'http://admin.test.host/login', [:user, :guest], { get: :index }

end
