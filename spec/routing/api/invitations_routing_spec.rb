require 'spec_helper'

describe Api::InvitationsController do
  
  it { should route(:post, "api/invitations").to(:action => :create) }
  
end