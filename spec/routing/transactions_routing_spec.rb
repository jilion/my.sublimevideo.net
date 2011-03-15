require 'spec_helper'

describe TransactionsController do

  it { should route(:post, "transaction/ok").to(:action => :ok) }
  it { should route(:post, "transaction/ko").to(:action => :ko) }

end
