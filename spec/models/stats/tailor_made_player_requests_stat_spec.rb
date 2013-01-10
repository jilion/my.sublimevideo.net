require 'spec_helper'

describe Stats::TailorMadePlayerRequestsStat do

  context "with a bunch of different tailor_made_player_requests" do

    before do
      create(:tailor_made_player_request, created_at: 5.days.ago.midnight, topic: 'agency')
      create(:tailor_made_player_request, created_at: 1.day.ago.midnight, topic: 'agency')
      create(:tailor_made_player_request, created_at: 1.day.ago.midnight, topic: 'standalone')
      create(:tailor_made_player_request, created_at: 1.day.ago.midnight, topic: 'standalone')
      create(:tailor_made_player_request, created_at: 1.day.ago.midnight, topic: 'platform')
      create(:tailor_made_player_request, created_at: 1.day.ago.midnight, topic: 'other')
      create(:tailor_made_player_request, created_at: 1.day.ago.midnight, topic: 'other')
      create(:tailor_made_player_request, created_at: 1.day.ago.midnight, topic: 'other')
    end

    describe ".create_stats" do
      it "creates tailor_made_player_requests_stats for the last 5 days" do
        described_class.create_stats
        described_class.count.should eq 5
      end

      it "creates tailor_made_player_requests_stats for the last day" do
        described_class.create_stats
        tailor_made_player_requests_stat = described_class.last
        tailor_made_player_requests_stat.n.should eq({ 'agency' => 1, 'standalone' => 2, 'platform' => 1, 'other' => 3 })
      end
    end

  end

end
