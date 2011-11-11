require 'spec_helper'

describe VideoTagsController do

  verb_and_actions = { get: [:show] }
  it_should_behave_like "redirect when connected as", '/suspended', [[:user, state: 'suspended']], verb_and_actions, site_id: "1", id: "2"
  it_should_behave_like "redirect when connected as", '/login', [:guest], verb_and_actions, site_id: "1", id: "2"

end
