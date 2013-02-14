require 'fast_spec_helper'
require 'sidekiq'
require 'config/redis'

require 'models/pusher_channel'

describe PusherChannel do

  describe "occupied / vacated", :redis do
    context "new channel" do
      subject { PusherChannel.new('stats') }

      it { should_not be_occupied }
      it { should be_vacated }
    end

    context "new channel occupied" do
      subject { PusherChannel.new('stats') }
      before { subject.occupied! }

      it { should be_occupied }
      it { should_not be_vacated }
    end

    context "new channel vacated after being occupied" do
      subject { PusherChannel.new('stats') }
      before { subject.occupied! && subject.vacated! }

      it { should_not be_occupied }
      it { should be_vacated }
    end
  end

  describe "#private? / #public? " do
    context "with private channel" do
      subject { PusherChannel.new('private-site_token') }

      it { should be_private }
      it { should_not be_public }
    end

    context "with public channel" do
      subject { PusherChannel.new('stats') }

      it { should be_public }
      it { should_not be_private }
    end
  end

  describe "#to_s" do
    it "returns channel name" do
      PusherChannel.new('stats').to_s.should eq 'stats'
    end
  end

end
