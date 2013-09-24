# coding: utf-8
require 'spec_helper'

describe Admin::AdminHelper do
  include Devise::TestHelpers

  describe "#current_utc_time" do
    it { helper.current_utc_time.should eq "<strong>Current UTC time:</strong> #{l(Time.now.utc, format: :seconds_timezone)}" }
  end

  describe "#distance_of_time_in_words_to_now" do
    it { helper.distance_of_time_in_words_to_now(3.seconds.ago).should match 'ago' }
    it { helper.distance_of_time_in_words_to_now(3.seconds.from_now).should match 'from now' }
  end

  describe "#viped" do
    it { helper.viped(double(vip?: false)) { 'foo' }.should eq 'foo' }
    it { helper.viped(double(vip?: true)) { 'foo' }.should eq '★foo★' }
  end

  describe "#formatted_pluralize" do
    it { helper.formatted_pluralize(42000, 'item').should eq '42&#39;000 items' }
    it { helper.formatted_pluralize(1, 'item').should eq '1 item' }
    it { helper.formatted_pluralize(0, 'item').should eq '0 items' }
  end

  describe "#display_tags_list" do
    let(:tags) { [double(name: 'foo', count: 42), double(name: 'bar', count: 13)] }

    it { helper.display_tags_list(tags).should eq '<a href="/docs?tagged_with=foo">foo (42)</a> | <a href="/docs?tagged_with=bar">bar (13)</a>' }
    it { helper.display_tags_list(tags, :tag).should eq '<a href="/docs?tag=foo">foo (42)</a> | <a href="/docs?tag=bar">bar (13)</a>' }
  end

end
