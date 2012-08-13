require "test_helper"

describe Zendesk::Client::Tickets do
  before do
    @zendesk = Zendesk::Client.new do |config|
      config.account = ENDPOINT
      config.basic_auth EMAIL, PASSWORD
    end

#     @ticket_id = ENV["LIVE"] ? @zendesk.tickets[-1]["id"] : 123
  end

  describe "Tickets API" do
    it "should fit this API" do
#       # POST
#       ticket = @zendesk.tickets.create do |t|
#         t[:subject] = "help, my toilet fell into the toilet"
#         t[:description] = "not my fault"
#       end

#       # GET
#       @zendesk.tickets(ticket.id).fetch
# 
#       # PUT
#       @zendesk.tickets(ticket.id).update do |t|
#         t[:set_tags] = "yikes"
#       end
# 
#       # DELETE
#       @zendesk.tickets(ticket.id).delete
    end
  end

end
