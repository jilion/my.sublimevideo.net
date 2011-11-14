require 'spec_helper'

describe My::TransactionsController do

  it { post(with_subdomain('my', 'transaction/callback')).should route_to('my/transactions#callback') }

end
