require 'spec_helper'

describe My::UsersController do

  before(:each) { request.env['devise.mapping'] = Devise.mappings[:user] }

  it_should_behave_like "redirect when connected as", 'http://my.test.host/login', [:guest], { put: :update }, nil

end
