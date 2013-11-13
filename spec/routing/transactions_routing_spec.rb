require 'spec_helper'

describe TransactionsController do

  it { expect(post(with_subdomain('my', 'transaction/callback'))).to route_to('transactions#callback') }

end
