require 'spec_helper'

describe My::Users::RegistrationsController do
  before(:each) { request.env['devise.mapping'] = Devise.mappings[:user] }

  it_should_behave_like "redirect when connected as", '/suspended', [[:user, { state: 'suspended' }]], { delete: :destroy }

end
