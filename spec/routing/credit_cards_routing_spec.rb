require 'spec_helper'

describe CreditCardsController do

  it { { get: 'card/edit' }.should route_to(controller: 'credit_cards', action: 'edit') }
  it { { put: 'card' }.should route_to(controller: 'credit_cards', action: 'update') }

end
