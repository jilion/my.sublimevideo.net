require "spec_helper"

describe TicketsController do

  it { should route(:get, "/support").to(:action => "new") }
  it { should route(:post, "/support").to(:action => "create") }

end
