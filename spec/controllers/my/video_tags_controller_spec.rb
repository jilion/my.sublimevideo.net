require 'spec_helper'

describe My::VideoTagsController do

  verb_and_actions = { get: [:show] }
  it_should_behave_like "redirect when connected as", 'http://my.test.host/suspended', [[:user, state: 'suspended']], verb_and_actions, site_id: '1', id: '2'
  it_should_behave_like "redirect when connected as", 'http://test.host/', [:guest], verb_and_actions, site_id: '1', id: '2'

end
