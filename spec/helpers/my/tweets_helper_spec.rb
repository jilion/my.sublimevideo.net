# coding: utf-8
require 'spec_helper'

describe My::TweetsHelper do

  describe "#clean_tweet_text" do
    context "with entities" do
      use_vcr_cassette "twitter/14786759290"
      subject { Twitter.status(14786759290, include_entities: true) }

      it "should do nothing special with no options" do
        helper.clean_tweet_text(subject).should eq "Help with the oil spill using @appcelerator #titanium and the awesome @intridea Oil Reporter API . http://bit.ly/dCueLT"
      end

      it "should remove user mentions whit the strip_user_mentions option" do
        helper.clean_tweet_text(subject, strip_user_mentions: true).should eq "Help with the oil spill using #titanium and the awesome Oil Reporter API . http://bit.ly/dCueLT"
      end

      it "should remove urls whit the strip_urls option" do
        helper.clean_tweet_text(subject, strip_urls: true).should eq "Help with the oil spill using @appcelerator #titanium and the awesome @intridea Oil Reporter API ."
      end

      it "should remove hashtags whit the strip_hastags option" do
        helper.clean_tweet_text(subject, strip_hastags: true).should eq "Help with the oil spill using @appcelerator and the awesome @intridea Oil Reporter API . http://bit.ly/dCueLT"
      end

      it "should remove user mentions, urls and hashtags whit the strip_user_mentions, strip_urls and strip_hastagsoption" do
        helper.clean_tweet_text(subject, strip_user_mentions: true, strip_urls: true, strip_hastags: true).should eq "Help with the oil spill using and the awesome Oil Reporter API ."
      end
    end

    context "with / cc" do
      use_vcr_cassette "twitter/53152800456179712"
      subject { Twitter.status(53152800456179712, include_entities: true) }

      it "should do nothing special with the strip_cc option" do
        helper.clean_tweet_text(subject, strip_cc: true).should eq "I want to be like @Jilion when I grow up. Their video player hosting service looks amazing. Kudos!"
      end
    end

    context "with /cc" do
      use_vcr_cassette "twitter/53134759622217728"
      subject { Twitter.status(53134759622217728, include_entities: true) }

      it "should do nothing special with the strip_cc option" do
        helper.clean_tweet_text(subject, strip_cc: true).should eq "SublimeVideo is now commercially available. We use it on @methodandcraft and absolutely love it!\n\nhttp://t.co/iqfdo81"
      end

      it "should do nothing special with the strip_cc and strip_urls options" do
        helper.clean_tweet_text(subject, strip_cc: true, strip_urls: true).should eq "SublimeVideo is now commercially available. We use it on @methodandcraft and absolutely love it!"
      end
    end
  end

end
