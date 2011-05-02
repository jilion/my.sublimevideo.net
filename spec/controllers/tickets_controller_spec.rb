require 'spec_helper'

describe TicketsController do

  it_should_behave_like "redirect when connected as", '/login', [:guest], { :get => :new, :post => :create }

end