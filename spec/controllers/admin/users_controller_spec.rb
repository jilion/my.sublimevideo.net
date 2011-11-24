require 'spec_helper'

describe Admin::UsersController do

  it_should_behave_like "redirect when connected as", '/login', [:user, :guest], { get: [:index, :show, :become] }

end
