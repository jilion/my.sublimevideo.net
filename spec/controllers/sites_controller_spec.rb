require 'spec_helper'

describe SitesController do

  verb_and_actions = { get: [:index, :edit], put: :update, delete: :destroy }
  it_behaves_like "redirect when connected as", 'http://my.test.host/suspended', [[:user, { state: 'suspended' }]], verb_and_actions
  it_behaves_like "redirect when connected as", 'http://my.test.host/login', [:guest], verb_and_actions

end
