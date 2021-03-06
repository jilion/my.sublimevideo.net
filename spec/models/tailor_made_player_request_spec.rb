require 'fast_spec_helper'
require 'active_support/core_ext'
require 'sublime_video_private_api/model'
require 'support/private_api_helpers'

require 'models/tailor_made_player_request'

describe TailorMadePlayerRequest do
  let(:attributes) { {
    "document" => { "url" => 'foo' },
  } }
  let(:topics) { %w[agency standalone platform other] }

  before do
    stub_api_for(TailorMadePlayerRequest) do |stub|
      stub.get("/private_api/tailor_made_player_requests/1") { |env| [200, {}, attributes.to_json] }
      stub.get("/private_api/tailor_made_player_requests/topics") { |env| [200, {}, topics.to_json] }
    end
  end

  describe "instance" do
    subject { TailorMadePlayerRequest.find(1) }

    its(:document_url) { should eq 'foo' }

    it "has a document" do
      subject.document?.should be_true
    end
  end

  describe ".topics" do
    it "returns all topics" do
      TailorMadePlayerRequest.topics.should eq topics
    end
  end
end
