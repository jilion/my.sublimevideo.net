require 'spec_helper'

describe TailorMadePlayerRequestsTrend do

  context "with a bunch of different tailor_made_player_requests" do
    let(:topics) { %w[agency platform] }
    let(:tailor_made_player_request) {
      TailorMadePlayerRequest.new(created_at: 2.days.ago.midnight.to_s, topic: 'agency')
    }
    before {
      TailorMadePlayerRequest.stub(:all) { [tailor_made_player_request] }
      TailorMadePlayerRequest.stub(:topics) { topics }
      TailorMadePlayerRequest.stub(:count) { 5 }
    }

    describe ".create_trends" do
      it "creates tailor_made_player_requests_stats for the last 5 days" do
        described_class.create_trends
        described_class.count.should eq 2
      end

      it "creates tailor_made_player_requests_stats for the last day" do
        TailorMadePlayerRequest.should_receive(:count).with(with_topic: 'agency', created_before: 2.days.ago.end_of_day) { 1 }
        TailorMadePlayerRequest.should_receive(:count).with(with_topic: 'agency', created_before: 1.days.ago.end_of_day) { 2 }
        TailorMadePlayerRequest.should_receive(:count).with(with_topic: 'platform', created_before: 2.days.ago.end_of_day) { 3 }
        TailorMadePlayerRequest.should_receive(:count).with(with_topic: 'platform', created_before: 1.days.ago.end_of_day) { 4 }
        described_class.create_trends
        described_class.order_by(d: 1).first.n.should eq({ 'agency' => 1, 'platform' => 3 })
        described_class.order_by(d: 1).last.n.should eq({ 'agency' => 2, 'platform' => 4 })
      end
    end

    describe ".update_trends" do
      before {
        described_class.create(d: 2.days.ago.midnight, n: {
          'agency' => 2, 'platform' => 2
        })
        described_class.create(d: 1.days.ago.midnight, n: {
          'agency' => 2, 'platform' => 2
        })
      }

      it "updates tailor_made_player_requests_stats for all days" do
        described_class.update_trends
        described_class.order_by(d: 1).first.n.should eq({ 'agency' => 5, 'platform' => 5 })
        described_class.order_by(d: 1).last.n.should eq({ 'agency' => 5, 'platform' => 5 })
      end

      it "updates tailor_made_player_requests_stats for the given day" do
        described_class.update_trends(1.day.ago.midnight)
        described_class.order_by(d: 1).first.n.should eq({ 'agency' => 2, 'platform' => 2 })
        described_class.order_by(d: 1).last.n.should eq({ 'agency' => 5, 'platform' => 5 })
      end
    end

  end

  describe '.json' do
    before do
      create(:tailor_made_player_requests_trend, d: Time.now.utc.midnight)
    end
    subject { JSON.parse(described_class.json) }

    its(:size) { should eq 1 }
    it { subject[0]['id'].should eq(Time.now.utc.midnight.to_i) }
    it { subject[0].should have_key('n') }
  end

end
