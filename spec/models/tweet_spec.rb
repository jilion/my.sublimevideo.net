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

  describe '.create_from_twitter_tweet!' do
    let(:twitter_tweet) do
      double(
        id: 42,
        in_reply_to_user_id: 2,
        in_reply_to_screen_name: 'bar',
        user: double(
          id: 1,
          screen_name: 'foo',
          profile_image_url_https: 'https://twitter.com/image.jpg',
        ),
        lang: 'fr',
        source: 'twitter',
        text: 'foo bar sublimevideo',
        created_at: Time.now.utc
      )
    end

    it 'saves the tweet from a real tweet' do
      described_class.create_from_twitter_tweet!(twitter_tweet)

      tweet = Tweet.last
      expect(tweet.tweet_id).to eq          twitter_tweet.id
      expect(tweet.keywords).to eq          ['sublimevideo']
      expect(tweet.from_user_id).to eq      twitter_tweet.user.id
      expect(tweet.from_user).to eq         twitter_tweet.user.screen_name
      expect(tweet.to_user_id).to eq        twitter_tweet.in_reply_to_user_id
      expect(tweet.to_user).to eq           twitter_tweet.in_reply_to_screen_name
      expect(tweet.iso_language_code).to eq twitter_tweet.lang
      expect(tweet.profile_image_url).to eq twitter_tweet.user.profile_image_url_https
      expect(tweet.source).to eq            twitter_tweet.source
      expect(tweet.content).to eq           twitter_tweet.text
      expect(tweet.tweeted_at.to_i).to eq   twitter_tweet.created_at.to_i
    end
  end

  describe "#favorite!", :vcr do
    subject { create(:tweet, tweet_id: 56351930166935552) }

    describe "favorite" do
      it "should favorite locally and on Twitter itself" do
        subject.should_not be_favorited
        subject.favorite!
        subject.should be_favorited
        TwitterWrapper.status(56351930166935552).favorited.should be_true
      end
    end

    describe "un-favorite" do
      it "should un-favorite locally and on Twitter if already favorited" do
        subject.should_not be_favorited
        subject.favorite!
        subject.should be_favorited
        TwitterWrapper.status(56351930166935552).favorited.should be_true
        subject.favorite!
        subject.should_not be_favorited
        TwitterWrapper.status(56351930166935552).favorited.should be_false
      end
    end
  end

end
