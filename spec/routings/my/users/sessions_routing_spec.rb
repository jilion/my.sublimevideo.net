require 'spec_helper'

describe My::Users::SessionsController do

  it { post('login').should  route_to('my/users/sessions#create') }

end
