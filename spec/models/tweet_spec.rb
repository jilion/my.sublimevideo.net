require 'spec_helper'

describe Tweet do

  context "Factory" do
    subject { build(:tweet) }

    its(:tweet_id)          { should be_present }
    its(:keywords)          { should eq %w[sublimevideo jilion] }
    its(:from_user_id)      { should eq 1 }
    its(:from_user)         { should eq 'toto' }
    its(:to_user_id)        { should eq 2 }
    its(:to_user)           { should eq 'tata' }
    its(:iso_language_code) { should eq 'en' }
    its(:profile_image_url) { should eq 'http://yourimage.com/img.jpg' }
    its(:content)           { should eq 'This is my first tweet!' }
    its(:tweeted_at)        { should be_present }
    its(:favorited)         { should be_false }

    it { should be_valid }
  end

  describe "Associations" do
    it "should belongs to retweeted_tweet" do
      tweet1 = create(:tweet, tweet_id: 1)
      tweet2 = create(:tweet, tweet_id: 2)
      tweet2.retweeted_tweet = tweet1
      tweet2.save

      tweet2.retweeted_tweet.should eq tweet1
    end

    it "retweets should be the inverse of retweeted_tweet" do
      tweet1 = create(:tweet, tweet_id: 1)
      tweet2 = create(:tweet, tweet_id: 2)
      tweet2.retweeted_tweet = tweet1
      tweet2.save

      tweet1.retweets.should eq [tweet2]
    end

    it "should have many retweets" do
      tweet1 = create(:tweet, tweet_id: 1)
      tweet2 = create(:tweet, tweet_id: 2)
      tweet3 = create(:tweet, tweet_id: 3)

      tweet1.retweets << tweet2
      tweet1.retweets << tweet3
      tweet1.save

      tweet1.retweets.entries.sort_by(&:tweet_id).should eq [tweet2, tweet3]
    end

    it "retweeted_tweet should be the inverse of retweets" do
      tweet1 = create(:tweet, tweet_id: 1)
      tweet2 = create(:tweet, tweet_id: 2)
      tweet3 = create(:tweet, tweet_id: 3)

      tweet1.retweets << tweet2
      tweet1.retweets << tweet3
      tweet1.save

      tweet2.retweeted_tweet.should eq tweet1
      tweet3.retweeted_tweet.should eq tweet1
    end
  end

  describe "Scopes" do
  end

  describe "Validations" do
    [:tweet_id, :keywords, :from_user_id, :from_user, :to_user_id, :to_user, :iso_language_code, :profile_image_url, :source, :content, :tweeted_at, :retweets_count].each do |attr|
      it { should allow_mass_assignment_of(attr) }
    end

    # Devise checks presence/uniqueness/format of email, presence/length of password
    it { should validate_presence_of(:tweet_id) }
    it { should validate_presence_of(:from_user_id) }
    it { should validate_presence_of(:content) }
    it { should validate_presence_of(:tweeted_at) }
    it "should validate uniqueness of tweet_id" do
      create(:tweet, tweet_id: 1)
      tweet = build(:tweet, tweet_id: 1)
      tweet.should_not be_valid
      tweet.should have(1).error_on(:tweet_id)
    end
  end

  describe "Class Methods" do
    describe ".save_new_tweets_and_sync_favorite_tweets" do
      before do
        # fake keywords to not fill the cassette...
        described_class.send(:remove_const, :KEYWORDS)
        described_class::KEYWORDS = %w[rymai]
      end
      use_vcr_cassette "twitter/save_new_tweets_and_sync_favorite_tweets"
      subject { described_class.save_new_tweets_and_sync_favorite_tweets }

      it "should create new tweets" do
        expect { subject }.to change(Tweet, :count)
      end

      it "should not create new tweets if they're all already saved" do
        expect { subject }.to change(Tweet, :count)
        expect { described_class.save_new_tweets_and_sync_favorite_tweets }.to_not change(Tweet, :count)
      end

      it "should call sync_favorite_tweets" do
        described_class.should_receive(:sync_favorite_tweets)
        subject
      end
    end

    describe ".enough_remaining_twitter_calls?" do
      it "should return true if remaining calls are >= KEYWORDS.size * 3" do
        TwitterApi.should_receive(:rate_limit_status).and_return(mock('rate_limit_status', remaining_hits: Tweet::KEYWORDS.size*3))
        described_class.enough_remaining_twitter_calls?.should be_true
      end

      it "should return false if remaining calls are < KEYWORDS.size * 3" do
        TwitterApi.should_receive(:rate_limit_status).and_return(mock('rate_limit_status', remaining_hits: Tweet::KEYWORDS.size*3 - 1))
        described_class.enough_remaining_twitter_calls?.should be_false
      end

      it "should return true if remaining calls are >= given count" do
        TwitterApi.should_receive(:rate_limit_status).and_return(mock('rate_limit_status', remaining_hits: 100))
        described_class.enough_remaining_twitter_calls?(100).should be_true
      end

      it "should return false if remaining calls are < given count" do
        TwitterApi.should_receive(:rate_limit_status).and_return(mock('rate_limit_status', remaining_hits: 99))
        described_class.enough_remaining_twitter_calls?(100).should be_false
      end
    end
  end

  describe "Instance Methods" do
    describe "#favorite!" do
      subject { create(:tweet, tweet_id: 56351930166935552) }

      describe "favorite" do
        use_vcr_cassette "twitter/favorite"

        it "should favorite locally and on Twitter itself" do
          subject.should_not be_favorited
          subject.favorite!
          subject.should be_favorited
          TwitterApi.status(56351930166935552).favorited.should be_true
        end
      end

      describe "un-favorite" do
        use_vcr_cassette "twitter/unfavorite"

        it "should un-favorite locally and on Twitter if already favorited" do
          subject.should_not be_favorited
          subject.favorite!
          subject.should be_favorited
          TwitterApi.status(56351930166935552).favorited.should be_true
          subject.favorite!
          subject.should_not be_favorited
          TwitterApi.status(56351930166935552).favorited.should be_false
        end
      end
    end
  end

end
