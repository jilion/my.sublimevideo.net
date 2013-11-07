require 'spec_helper'

describe Admin::App::ComponentVersionsController do

  it_behaves_like "redirect when connected as",
    'http://admin.test.host/login',
    [:authenticated_user, :guest],
    { get: [:index, :show], post: :create, delete: :destroy },
    component_id: '1'

  it_behaves_like "redirect when connected as",
    'http://admin.test.host/sites',
    [[:admin, { roles: ['marcom'] }]],
    { get: [:index, :show], post: :create, delete: :destroy },
    component_id: '1'

end
