require 'spec_helper'

describe My::UsersController do

  it_should_behave_like "redirect when connected as", '/login', [:guest], { put: :update }, nil

end
