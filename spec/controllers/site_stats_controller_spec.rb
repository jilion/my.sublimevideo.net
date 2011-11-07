require 'spec_helper'

describe SiteStatsController do

  verb_and_actions = { get: [:index], put: [:trial] }
  it_should_behave_like "redirect when connected as", '/suspended', [[:user, state: 'suspended']], verb_and_actions, site_id: "1"
  it_should_behave_like "redirect when connected as", '/login', [:guest], verb_and_actions, site_id: "1"

end