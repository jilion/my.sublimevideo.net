require 'spec_helper'

describe Admin::Admins::InvitationsController do

  before(:each) { request.env['devise.mapping'] = Devise.mappings[:admin] }

  it_should_behave_like "redirect when connected as", '/admin/login', [:user, :guest], { :get => :new, :post => :create }

end
