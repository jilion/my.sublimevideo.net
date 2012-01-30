require 'spec_helper'

describe Stats::TweetsStat do

  context "with a bunch of different tweet" do
    before(:each) do
      Factory.create(:tweet, tweeted_at: 5.days.ago.midnight, keywords: %w[sublimevideo])
      Factory.create(:tweet, tweeted_at: 1.day.ago.midnight, keywords: %w[jilion videojs sublimevideo])
      Factory.create(:tweet, tweeted_at: 1.day.ago.midnight, keywords: ["jw player", "videojs"])
      Factory.create(:tweet, tweeted_at: 1.day.ago.midnight, keywords: %w[jilion aelios aeliosapp])
    end

    describe ".create_stats" do

      it "should delay itself" do
        described_class.should_receive(:delay_create_stats)
        described_class.create_stats
      end

      it "should create tweets stats for the last 5 days" do
        described_class.create_stats
        described_class.count.should eq 5
        tweets_stat = described_class.last
        tweets_stat.k.should eq({ 'jilion' => 2, 'videojs' => 2, 'sublimevideo' => 1, 'jw player' => 1, 'aelios' => 1, 'aeliosapp' => 1 })
      end

      it "should create site_stats stats for the last 2 days" do
        described_class.create(d: 2.days.ago.midnight)
        described_class.create_stats
        described_class.count.should eq 1 + 2
      end
    end
  end

end
