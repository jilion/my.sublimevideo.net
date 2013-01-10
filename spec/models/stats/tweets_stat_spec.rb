require 'spec_helper'

describe Stats::TweetsStat do

  context "with a bunch of different tweets" do

    before do
      create(:tweet, tweeted_at: 5.days.ago.midnight, keywords: %w[sublimevideo])
      create(:tweet, tweeted_at: 1.day.ago.midnight, keywords: %w[jilion videojs sublimevideo])
      create(:tweet, tweeted_at: 1.day.ago.midnight, keywords: ["jw player", "videojs"])
      create(:tweet, tweeted_at: 1.day.ago.midnight, keywords: %w[jilion aelios aeliosapp])
    end

    describe ".create_stats" do
      it "creates tweets_stats for the last 5 days" do
        described_class.create_stats
        described_class.count.should eq 5
      end

      it "creates tweets_stats stats for the last day" do
        described_class.create_stats
        tweets_stat = described_class.last
        tweets_stat.k.should eq({ 'jilion' => 2, 'videojs' => 2, 'sublimevideo' => 1, 'jw player' => 1, 'aelios' => 1, 'aeliosapp' => 1 })
      end
    end

  end

end
