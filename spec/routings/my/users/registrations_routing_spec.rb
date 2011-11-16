require 'spec_helper'

describe My::Users::RegistrationsController do

  it { post('signup').should route_to('my/users/registrations#create') }

end
