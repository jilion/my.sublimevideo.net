# coding: utf-8
require 'spec_helper'

describe Admin::AdminHelper do
  include Devise::TestHelpers

  describe "#current_utc_time" do
    it { expect(helper.current_utc_time).to eq "<strong>Current UTC time:</strong> #{l(Time.now.utc, format: :seconds_timezone)}" }
  end

  describe "#distance_of_time_in_words_to_now" do
    it { expect(helper.distance_of_time_in_words_to_now(3.seconds.ago)).to match 'ago' }
    it { expect(helper.distance_of_time_in_words_to_now(3.seconds.from_now)).to match 'from now' }
  end

  describe "#viped" do
    it { expect(helper.viped(double(vip?: false)) { 'foo' }).to eq 'foo' }
    it { expect(helper.viped(double(vip?: true)) { 'foo' }).to eq '★foo★' }
  end

  describe "#formatted_pluralize" do
    it { expect(helper.formatted_pluralize(42000, 'item')).to eq '42,000 items' }
    it { expect(helper.formatted_pluralize(1, 'item')).to eq '1 item' }
    it { expect(helper.formatted_pluralize(0, 'item')).to eq '0 items' }
  end

  describe "#display_tags_list" do
    let(:tags) { [double(name: 'foo', count: 42), double(name: 'bar', count: 13)] }

    it { expect(helper.display_tags_list(tags)).to eq '<a href="/docs?tagged_with=foo">foo (42)</a> | <a href="/docs?tagged_with=bar">bar (13)</a>' }
    it { expect(helper.display_tags_list(tags, :tag)).to eq '<a href="/docs?tag=foo">foo (42)</a> | <a href="/docs?tag=bar">bar (13)</a>' }
  end

end
