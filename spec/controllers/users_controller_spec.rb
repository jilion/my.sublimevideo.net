require 'spec_helper'

describe UsersController do

  it_should_behave_like "redirect when connected as", '/login', [:guest], { :put => :update }, nil

end
