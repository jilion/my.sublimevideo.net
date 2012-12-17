require 'spec_helper'

describe TransactionsController do

  it { post(with_subdomain('my', 'transaction/callback')).should route_to('transactions#callback') }

end
