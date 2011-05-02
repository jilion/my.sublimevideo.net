require 'spec_helper'

describe RefundsController do

  verb_and_actions = { :get => :index, :post => :create }
  it_should_behave_like "redirect when connected as", '/login', [:guest], verb_and_actions

end
