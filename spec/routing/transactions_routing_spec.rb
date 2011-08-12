require 'spec_helper'

describe TransactionsController do

  it { { post: 'transaction/callback' }.should route_to(controller: 'transactions', action: 'callback') }

end
