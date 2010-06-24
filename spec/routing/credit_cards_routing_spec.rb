require 'spec_helper'

describe CreditCardsController do
  
  it { should route(:get, "card/edit").to(:action => :edit) }
  it { should route(:put, "card").to(:action => :update) }
  
end