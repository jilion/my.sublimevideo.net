require 'spec_helper'

describe Admin::DashboardsController do

  it_should_behave_like "redirect when connected as", '/admin/login', [:user, :guest], { :get => :show }

end
