require 'spec_helper'

describe Tweet do

  context "Factory" do
    subject { build(:tweet) }

    describe '#tweet_id' do
      subject { super().tweet_id }
      it          { should be_present }
    end

    describe '#keywords' do
      subject { super().keywords }
      it          { should eq %w[sublimevideo jilion] }
    end

    describe '#from_user_id' do
      subject { super().from_user_id }
      it      { should eq 1 }
    end

    describe '#from_user' do
      subject { super().from_user }
      it         { should eq 'toto' }
    end

    describe '#to_user_id' do
      subject { super().to_user_id }
      it        { should eq 2 }
    end

    describe '#to_user' do
      subject { super().to_user }
      it           { should eq 'tata' }
    end

    describe '#iso_language_code' do
      subject { super().iso_language_code }
      it { should eq 'en' }
    end

    describe '#profile_image_url' do
      subject { super().profile_image_url }
      it { should eq 'http://yourimage.com/img.jpg' }
    end

    describe '#content' do
      subject { super().content }
      it           { should eq 'This is my first tweet!' }
    end

    describe '#tweeted_at' do
      subject { super().tweeted_at }
      it        { should be_present }
    end

    describe '#favorited' do
      subject { super().favorited }
      it         { should be_falsey }
    end

    it { should be_valid }
  end

  describe "Associations" do
    it "should belongs to retweeted_tweet" do
      tweet1 = create(:tweet, tweet_id: 1)
      tweet2 = create(:tweet, tweet_id: 2)
      tweet2.retweeted_tweet = tweet1
      tweet2.save

      expect(tweet2.retweeted_tweet).to eq tweet1
    end

    it "retweets should be the inverse of retweeted_tweet" do
      tweet1 = create(:tweet, tweet_id: 1)
      tweet2 = create(:tweet, tweet_id: 2)
      tweet2.retweeted_tweet = tweet1
      tweet2.save

      expect(tweet1.retweets).to eq [tweet2]
    end

    it "should have many retweets" do
      tweet1 = create(:tweet, tweet_id: 1)
      tweet2 = create(:tweet, tweet_id: 2)
      tweet3 = create(:tweet, tweet_id: 3)

      tweet1.retweets << tweet2
      tweet1.retweets << tweet3
      tweet1.save

      expect(tweet1.retweets.entries.sort_by(&:tweet_id)).to eq [tweet2, tweet3]
    end

    it "retweeted_tweet should be the inverse of retweets" do
      tweet1 = create(:tweet, tweet_id: 1)
      tweet2 = create(:tweet, tweet_id: 2)
      tweet3 = create(:tweet, tweet_id: 3)

      tweet1.retweets << tweet2
      tweet1.retweets << tweet3
      tweet1.save

      expect(tweet2.retweeted_tweet).to eq tweet1
      expect(tweet3.retweeted_tweet).to eq tweet1
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
      expect(tweet).not_to be_valid
      expect(tweet.errors[:tweet_id].size).to eq(1)
    end
  end

  describe '.create_from_twitter_tweet!' do
    let(:twitter_tweet) do
      double(
        id: 42,
        user: double(id: 1, profile_image_url_https: 'https://twitter.com/image.jpg'),
        from_user_id: 12,
        from_user: 'foo',
        to_user_id: 2,
        to_user: 'bar',
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
      expect(tweet.from_user_id).to eq      twitter_tweet.from_user_id
      expect(tweet.from_user).to eq         twitter_tweet.from_user
      expect(tweet.to_user_id).to eq        twitter_tweet.to_user_id
      expect(tweet.to_user).to eq           twitter_tweet.to_user
      expect(tweet.iso_language_code).to eq twitter_tweet.lang
      expect(tweet.profile_image_url).to eq twitter_tweet.user.profile_image_url_https
      expect(tweet.source).to eq            twitter_tweet.source
      expect(tweet.content).to eq           twitter_tweet.text
      expect(tweet.tweeted_at.to_i).to eq   twitter_tweet.created_at.to_i
    end

    context 'twitter tweet has no from_user_id' do
      before { allow(twitter_tweet).to receive(:from_user_id).and_return(nil) }

      it 'uses tweet.user.id instead of tweet.from_user_id' do
        described_class.create_from_twitter_tweet!(twitter_tweet)

        tweet = Tweet.last
        expect(tweet.from_user_id).to eq twitter_tweet.user.id
      end
    end
  end

  describe "#favorite!", :vcr do
    subject { create(:tweet, tweet_id: 56351930166935552) }

    describe "favorite" do
      it "should favorite locally and on Twitter itself" do
        expect(subject).not_to be_favorited
        subject.favorite!
        expect(subject).to be_favorited
        expect(TwitterWrapper.status(56351930166935552).favorited).to be_truthy
      end
    end

    describe "un-favorite" do
      it "should un-favorite locally and on Twitter if already favorited" do
        expect(subject).not_to be_favorited
        subject.favorite!
        expect(subject).to be_favorited
        expect(TwitterWrapper.status(56351930166935552).favorited).to be_truthy
        subject.favorite!
        expect(subject).not_to be_favorited
        expect(TwitterWrapper.status(56351930166935552).favorited).to be_falsey
      end
    end
  end

end
