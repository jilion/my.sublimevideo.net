require 'spec_helper'

describe My::SitesController do

  verb_and_actions = { get: [:index, :new, :edit, :state], post: :create, put: :update, delete: :destroy }
  it_should_behave_like "redirect when connected as", 'http://my.test.host/suspended', [[:user, { state: 'suspended' }]], verb_and_actions
  it_should_behave_like "redirect when connected as", 'http://test.host/', [:guest], verb_and_actions

end
