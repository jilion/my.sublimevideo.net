require 'spec_helper'

describe Admin::Admins::InvitationsController do

  before { request.env['devise.mapping'] = Devise.mappings[:admin] }

  it_behaves_like "redirect when connected as", 'http://admin.test.host/login', [:user, :guest], { get: :new, post: :create }

end
