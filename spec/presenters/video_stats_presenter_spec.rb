require 'fast_spec_helper'

require 'presenters/video_stats_presenter'

describe VideoStatsPresenter do
  FakeVideoStat = Struct.new(:time, :bp, :co, :de, :lo, :st)
  FakeLastVideoStat = Struct.new(:time, :lo, :st)
  FakeLastVideoPlay = Struct.new(:time, :lo, :st)
  before do
    stub_const('VideoStat', Class.new)
    stub_const('LastVideoStat', Class.new)
    stub_const('LastPlay', Class.new)
  end

  let(:video_tag) { double('VideoTag', uid: 'foobar') }
  let(:presenter) { described_class.new(video_tag) }
  let(:stats_by_hour) do
    [
      FakeVideoStat.new(
        1.hour.ago.change(min: 0),
        { 'w' => { 'saf-osx' => 1, 'iex-win' => 5 }, 'e' => { 'saf-osx' => 2, 'iex-win' => 5 } },
        { 'w' => { 'fr' => 5, 'ch' => 1 }, 'e' => { 'fr' => 5, 'ch' => 2 } },
        { 'w' => { 'd' => 5, 'm' => 2 }, 'e' => { 'd' => 5, 'm' => 1 } },
        nil,
        { 'w' => 3, 'e' => nil }),
      FakeVideoStat.new(
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
      FakeLastVideoStat.new(1.minutes.ago.change(sec: 0), nil, 3),
      FakeLastVideoStat.new(2.minutes.ago.change(sec: 0), 5, nil)
    ]
  end

  let(:last_plays) do
    [
      FakeLastVideoPlay.new(2.minutes.ago.change(sec: 0), 5, nil),
      FakeLastVideoPlay.new(1.minutes.ago.change(sec: 0), nil, 3)
    ]
  end

  describe '#_last_stats_by_hour' do
    it 'delegates to VideoStat.last_hours_stats' do
      expect(VideoStat).to receive(:last_hours_stats).with(video_tag, presenter.options[:hours] + 24) { stats_by_hour }

      presenter.send(:_last_stats_by_hour).should eq stats_by_hour.reverse
    end
  end

  describe '#_last_stats_by_minute' do
    it 'delegates to VideoStat.last_stats' do
      expect(LastVideoStat).to receive(:last_stats).with(video_tag) { stats_by_minute }

      presenter.send(:_last_stats_by_minute).should eq stats_by_minute.reverse
    end
  end

  describe '#last_plays' do
    it 'delegates to VideoStat.last_stats' do
      expect(LastVideoPlay).to receive(:last_plays).with(video_tag, presenter.options[:since]) { last_plays }

      presenter.last_plays.should eq last_plays
    end
  end

  describe '#etag' do
    it 'compute the etag from video tag uid and presenter options' do
      expect(presenter.etag).to eq "#{video_tag.uid}_#{presenter.options}"
    end
  end

end
