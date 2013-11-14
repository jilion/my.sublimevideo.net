require 'fast_spec_helper'

require 'presenters/site_stats_presenter'

describe SiteStatsPresenter do
  FakeSiteStat = Struct.new(:time, :bp, :co, :de, :lo, :st)
  FakeLastSiteStat = Struct.new(:time, :lo, :st)
  FakeLastSitePlay = Struct.new(:time, :lo, :st)
  before do
    stub_const('SiteStat', Class.new)
    stub_const('LastSiteStat', Class.new)
    stub_const('LastSitePlay', Class.new)
  end

  let(:site) { double('Site', token: 'foobar') }
  let(:presenter) { described_class.new(site) }
  let(:stats_by_hour) do
    [
      FakeSiteStat.new(
        1.hour.ago.change(min: 0),
        { 'w' => { 'saf-osx' => 1, 'iex-win' => 5 }, 'e' => { 'saf-osx' => 2, 'iex-win' => 5 } },
        { 'w' => { 'fr' => 5, 'ch' => 1 }, 'e' => { 'fr' => 5, 'ch' => 2 } },
        { 'w' => { 'd' => 5, 'm' => 2 }, 'e' => { 'd' => 5, 'm' => 1 } },
        nil,
        { 'w' => 3, 'e' => nil }),
      FakeSiteStat.new(
        2.hours.ago.change(min: 0),
        { 'w' => { 'saf-osx' => 1, 'iex-win' => 5 }, 'e' => { 'saf-osx' => 1, 'iex-win' => 5 } },
        { 'w' => { 'fr' => 5, 'ch' => 1 }, 'e' => { 'fr' => 5, 'ch' => 1 } },
        { 'w' => { 'd' => 5, 'm' => 1 }, 'e' => { 'd' => 5, 'm' => 1 } },
        { 'w' => nil, 'e' => 5 },
        nil)
    ]
  end

  let(:stats_by_minute) do
    [
      FakeLastSiteStat.new(1.minutes.ago.change(sec: 0), nil, 3),
      FakeLastSiteStat.new(2.minutes.ago.change(sec: 0), 5, nil)
    ]
  end

  let(:last_plays) do
    [
      FakeLastSitePlay.new(2.minutes.ago.change(sec: 0), 5, nil),
      FakeLastSitePlay.new(1.minutes.ago.change(sec: 0), nil, 3)
    ]
  end

  describe '#_last_stats_by_hour' do
    it 'delegates to VideoStat.last_hours_stats' do
      expect(SiteStat).to receive(:last_hours_stats).with(site, presenter.options[:hours] + 24) { stats_by_hour }

      presenter.send(:_last_stats_by_hour).should eq stats_by_hour.reverse
    end
  end

  describe '#_last_stats_by_minute' do
    it 'delegates to VideoStat.last_stats' do
      expect(LastSiteStat).to receive(:last_stats).with(site) { stats_by_minute }

      presenter.send(:_last_stats_by_minute).should eq stats_by_minute.reverse
    end
  end

  describe '#last_plays' do
    it 'delegates to VideoStat.last_stats' do
      expect(LastSitePlay).to receive(:last_plays).with(site, presenter.options[:since]) { last_plays }

      presenter.last_plays.should eq last_plays
    end
  end

  describe '#etag' do
    it 'compute the etag from video tag uid and presenter options' do
      expect(presenter.etag).to eq "#{site.token}_#{presenter.options}"
    end
  end

end
