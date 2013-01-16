require 'fast_spec_helper'
require File.expand_path('spec/support/her_helpers')
require File.expand_path('app/models/tailor_made_player_request')

describe TailorMadePlayerRequest do
  let(:attributes) { {
    "company" => "Test SA",
    "country" => "AS",
    "created_at" => 1.year.ago,
    "description" => "Test",
    "document" => { "url"=> nil },
    "email" => "test@test.com",
    "highrise_kase_id" => nil,
    "id" => 1,
    "job_title" => "Test",
    "name" => "Test",
    "topic" => "agency",
    "topic_other_detail" => "",
    "topic_standalone_detail" => "",
    "updated_at" => 1.year.ago,
    "url" => "test.com"
  } }
  let(:response_headers) { {
    'X-Page' => '1',
    'X-Per-Page' => '25',
    'X-Total-Count' => '2',
  } }


  before do
    stub_api_for(TailorMadePlayerRequest) do |stub|
      stub.get("/api/tailor_made_player_requests/1") { |env| [200, {}, attributes.to_json] }
      stub.get("/api/tailor_made_player_requests")   { |env| [200, response_headers, [attributes].to_json] }
    end
  end

  describe "find" do
    subject { TailorMadePlayerRequest.find(1) }
    its(:name) { should eq 'Test' }
    its(:created_at) { should be_kind_of(Time) }
  end

  describe "all" do
    it "returns a Kaminari array" do
      array = TailorMadePlayerRequest.all.page(1)
      array.total_count.should eq 2
    end
  end

end
