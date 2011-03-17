require 'spec_helper'

describe TransactionsController do

  it { should route(:post, "transaction/callback").to(:action => :ok) }

end
