require 'spec_helper'

describe TailorMadePlayerRequestsTrend do

  context "with a bunch of different tailor_made_player_requests" do
    let(:topics) { %w[agency platform] }
    let(:tailor_made_player_request) {
      TailorMadePlayerRequest.new(created_at: 2.days.ago.midnight.to_s, topic: 'agency')
    }
    before {
      allow(TailorMadePlayerRequest).to receive(:all) { [tailor_made_player_request] }
      allow(TailorMadePlayerRequest).to receive(:topics) { topics }
      allow(TailorMadePlayerRequest).to receive(:count) { 5 }
    }

    describe ".create_trends" do
      it "creates tailor_made_player_requests_stats for the last 5 days" do
        described_class.create_trends
        expect(described_class.count).to eq 2
      end

      it "creates tailor_made_player_requests_stats for the last day" do
        expect(TailorMadePlayerRequest).to receive(:count).with(with_topic: 'agency', created_before: 2.days.ago.end_of_day) { 1 }
        expect(TailorMadePlayerRequest).to receive(:count).with(with_topic: 'agency', created_before: 1.days.ago.end_of_day) { 2 }
        expect(TailorMadePlayerRequest).to receive(:count).with(with_topic: 'platform', created_before: 2.days.ago.end_of_day) { 3 }
        expect(TailorMadePlayerRequest).to receive(:count).with(with_topic: 'platform', created_before: 1.days.ago.end_of_day) { 4 }
        described_class.create_trends
        expect(described_class.order_by(d: 1).first.n).to eq({ 'agency' => 1, 'platform' => 3 })
        expect(described_class.order_by(d: 1).last.n).to eq({ 'agency' => 2, 'platform' => 4 })
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
        expect(described_class.order_by(d: 1).first.n).to eq({ 'agency' => 5, 'platform' => 5 })
        expect(described_class.order_by(d: 1).last.n).to eq({ 'agency' => 5, 'platform' => 5 })
      end

      it "updates tailor_made_player_requests_stats for the given day" do
        described_class.update_trends(1.day.ago.midnight)
        expect(described_class.order_by(d: 1).first.n).to eq({ 'agency' => 2, 'platform' => 2 })
        expect(described_class.order_by(d: 1).last.n).to eq({ 'agency' => 5, 'platform' => 5 })
      end
    end

  end

  describe '.json' do
    before do
      create(:tailor_made_player_requests_trend, d: Time.now.utc.midnight)
    end
    subject { JSON.parse(described_class.json) }

    describe '#size' do
      subject { super().size }
      it { should eq 1 }
    end
    it { expect(subject[0]['id']).to eq(Time.now.utc.midnight.to_i) }
    it { expect(subject[0]).to have_key('n') }
  end

end
