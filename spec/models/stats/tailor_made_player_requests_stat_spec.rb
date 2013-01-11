require 'spec_helper'

describe Stats::TailorMadePlayerRequestsStat do

  context "with a bunch of different tailor_made_player_requests" do

    before do
      create(:tailor_made_player_request, created_at: 5.days.ago.midnight, topic: 'agency')
      create(:tailor_made_player_request, created_at: 5.days.ago.midnight + 5.seconds, topic: 'platform')
      create(:tailor_made_player_request, created_at: 4.day.ago.midnight, topic: 'agency')
      create(:tailor_made_player_request, created_at: 3.day.ago.midnight, topic: 'standalone')
      create(:tailor_made_player_request, created_at: 2.day.ago.midnight, topic: 'standalone')
      create(:tailor_made_player_request, created_at: 2.day.ago.midnight + 5.seconds, topic: 'platform')
      create(:tailor_made_player_request, created_at: 1.day.ago.midnight, topic: 'other')
      create(:tailor_made_player_request, created_at: 1.day.ago.midnight + 5.seconds, topic: 'other')
      create(:tailor_made_player_request, created_at: 1.day.ago.midnight + 10.seconds, topic: 'other')
    end

    describe ".create_stats" do
      it "creates tailor_made_player_requests_stats for the last 5 days" do
        described_class.create_stats
        described_class.count.should eq 5
      end

      it "creates tailor_made_player_requests_stats for the last day" do
        described_class.create_stats
        described_class.order_by(d: 1).first.n.should eq({ 'agency' => 1, 'platform' => 1 })
        described_class.order_by(d: 1).last.n.should eq({ 'agency' => 2, 'standalone' => 2, 'platform' => 2, 'other' => 3 })
      end
    end

    describe ".update_stats" do
      it "updates tailor_made_player_requests_stats for all days" do
        described_class.create_stats
        described_class.order_by(d: 1).first.n.should eq({ 'agency' => 1, 'platform' => 1 })
        described_class.order_by(d: 1).last.n.should eq({ 'agency' => 2, 'standalone' => 2, 'platform' => 2, 'other' => 3 })

        TailorMadePlayerRequest.order(:created_at).first.destroy
        TailorMadePlayerRequest.order(:created_at).last.destroy

        described_class.update_stats

        described_class.order_by(d: 1).first.n.should eq({ 'platform' => 1 })
        described_class.order_by(d: 1).last.n.should eq({ 'agency' => 1, 'standalone' => 2, 'platform' => 2, 'other' => 2 })
      end

      it "updates tailor_made_player_requests_stats for the given day" do
        described_class.create_stats
        described_class.order_by(d: 1).first.n.should eq({ 'agency' => 1, 'platform' => 1 })
        described_class.order_by(d: 1).last.n.should eq({ 'agency' => 2, 'standalone' => 2, 'platform' => 2, 'other' => 3 })

        TailorMadePlayerRequest.order(:created_at).first.destroy
        TailorMadePlayerRequest.order(:created_at).last.destroy

        described_class.update_stats(2.day.ago.midnight)

        described_class.order_by(d: 1).first.n.should eq({ 'agency' => 1, 'platform' => 1 })
        described_class.order_by(d: 1).last.n.should eq({ 'agency' => 1, 'standalone' => 2, 'platform' => 2, 'other' => 2 })
      end
    end

  end

end
