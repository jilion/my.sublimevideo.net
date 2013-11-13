require 'spec_helper'

describe TweetsTrend do

  describe ".create_trends" do
    context "with a bunch of different tweets" do
      before do
        create(:tweet, tweeted_at: 5.days.ago.midnight, keywords: %w[sublimevideo])
        create(:tweet, tweeted_at: 1.day.ago.midnight, keywords: %w[jilion videojs sublimevideo])
        create(:tweet, tweeted_at: 1.day.ago.midnight, keywords: ["jw player", "videojs"])
        create(:tweet, tweeted_at: 1.day.ago.midnight, keywords: %w[jilion aelios aeliosapp])
      end

      it "creates tweets_stats for the last 5 days" do
        described_class.create_trends
        expect(described_class.count).to eq 5
      end

      it "creates tweets_stats stats for the last day" do
        described_class.create_trends
        tweets_stat = described_class.last
        expect(tweets_stat.k).to eq({ 'jilion' => 2, 'videojs' => 2, 'sublimevideo' => 1, 'jw player' => 1, 'aelios' => 1, 'aeliosapp' => 1 })
      end
    end
  end

  describe '.json' do
    before do
      create(:tweets_trend, d: Time.now.utc.midnight)
    end
    subject { JSON.parse(described_class.json) }

    describe '#size' do
      subject { super().size }
      it { should eq 1 }
    end
    it { expect(subject[0]['id']).to eq(Time.now.utc.midnight.to_i) }
    it { expect(subject[0]).to have_key('k') }
  end

end
