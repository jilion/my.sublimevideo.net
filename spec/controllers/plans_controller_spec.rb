require 'spec_helper'

describe PlansController do

  verb_and_actions = { get: :edit, put: :update }
  it_should_behave_like "redirect when connected as", 'http://my.test.host/suspended', [[:user, { state: 'suspended' }]], verb_and_actions, site_id: "1"
  it_should_behave_like "redirect when connected as", 'http://my.test.host/login', [:guest], verb_and_actions, site_id: '1'

end
