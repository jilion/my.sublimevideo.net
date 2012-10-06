require 'spec_helper'

describe Admin::App::ComponentsController do

  it_should_behave_like "redirect when connected as",
    'http://admin.test.host/login',
    [:authenticated_user, :guest],
    { get: [:index, :show], post: :create, put: :update, delete: :destroy }

  it_should_behave_like "redirect when connected as",
    'http://admin.test.host/sites',
    [[:admin, { roles: ['marcom'] }]],
    { get: [:index, :show], post: :create, put: :update, delete: :destroy }

end
