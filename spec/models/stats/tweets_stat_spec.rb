require 'spec_helper'

describe Stats::TweetsStat do

  describe ".delay_create_tweets_stats" do

    it "should delay create_tweets_stats if not already delayed" do
      expect { described_class.delay_create_tweets_stats }.to change(Delayed::Job.where(:handler.matches => '%Stats::TweetsStat%create_tweets_stats%'), :count).by(1)
    end

    it "should not delay create_tweets_stats if already delayed" do
      described_class.delay_create_tweets_stats
      expect { described_class.delay_create_tweets_stats }.to_not change(Delayed::Job.where(:handler.matches => '%Stats::TweetsStat%create_tweets_stats%'), :count)
    end

    it "should delay create_tweets_stats for next day" do
      described_class.delay_create_tweets_stats
      Delayed::Job.last.run_at.should eq Time.now.utc.tomorrow.midnight
    end

  end

  context "with a bunch of different tweet" do
    before(:each) do
      Factory.create(:tweet, tweeted_at: 5.days.ago.midnight, keywords: %w[sublimevideo])
      Factory.create(:tweet, tweeted_at: 1.day.ago.midnight, keywords: %w[jilion videojs sublimevideo])
      Factory.create(:tweet, tweeted_at: 1.day.ago.midnight, keywords: ["jw player", "videojs"])
      Factory.create(:tweet, tweeted_at: 1.day.ago.midnight, keywords: %w[jilion aelios aeliosapp])
    end

    describe ".create_tweets_stats" do

      it "should delay itself" do
        described_class.should_receive(:delay_create_tweets_stats)
        described_class.create_tweets_stats
      end

      it "should create tweets stats for the last 5 days" do
        described_class.create_tweets_stats
        described_class.count.should eq 5
        tweets_stat = described_class.last
        tweets_stat.k.should eq({ 'jilion' => 2, 'videojs' => 2, 'sublimevideo' => 1, 'jw player' => 1, 'aelios' => 1, 'aeliosapp' => 1 })
      end

      it "should create site_stats stats for the last 2 days" do
        described_class.create(d: 2.days.ago.midnight)
        described_class.create_tweets_stats
        described_class.count.should eq 1 + 1
      end

    end

  end

end
