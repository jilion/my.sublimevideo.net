require 'fast_spec_helper'

require 'presenters/stats_presenter'
require 'presenters/site_stats_presenter'

describe StatsPresenter do
  let(:presenter) { described_class.new(nil) }

  describe '#_last_stats_by_hour' do
    it 'must be implemented by a subclass' do
      expect { presenter.send :_last_stats_by_hour }.to raise_error(NotImplementedError)
    end
  end

  describe '#_last_stats_by_minute' do
    it 'must be implemented by a subclass' do
      expect { presenter.send :_last_stats_by_minute }.to raise_error(NotImplementedError)
    end
  end

  describe '#last_plays' do
    it 'must be implemented by a subclass' do
      expect { presenter.last_plays } .to raise_error(NotImplementedError)
    end
  end

  describe '#etag' do
    it 'must be implemented by a subclass' do
      expect { presenter.etag }.to raise_error(NotImplementedError)
    end
  end
end

describe SiteStatsPresenter do
  FakeSiteStat = Struct.new(:time, :bp, :co, :de, :lo, :st)
  FakeLastSiteStat = Struct.new(:time, :lo, :st)
  FakeLastSitePlay = Struct.new(:time, :lo, :st)
  before do
    stub_const('VideoStat', Class.new)
    stub_const('LastVideoStat', Class.new)
    stub_const('LastPlay', Class.new)
  end

  let(:site) { double('Site', token: 'foobar') }
  let(:presenter) { described_class.new(site) }
  let(:stats_by_hour) do
    [
      FakeSiteStat.new(
        2.hours.ago.change(min: 0),
        { 'w' => { 'saf-osx' => 1, 'iex-win' => 5 }, 'e' => { 'saf-osx' => 1, 'iex-win' => 5 } },
        { 'w' => { 'fr' => 5, 'ch' => 1 }, 'e' => { 'fr' => 5, 'ch' => 1 } },
        { 'w' => { 'd' => 5, 'm' => 1 }, 'e' => { 'd' => 5, 'm' => 1 } },
        { 'w' => nil, 'e' => 5 },
        nil),
      FakeSiteStat.new(
        1.hour.ago.change(min: 0),
        { 'w' => { 'saf-osx' => 1, 'iex-win' => 5 }, 'e' => { 'saf-osx' => 2, 'iex-win' => 5 } },
        { 'w' => { 'fr' => 5, 'ch' => 1 }, 'e' => { 'fr' => 5, 'ch' => 2 } },
        { 'w' => { 'd' => 5, 'm' => 2 }, 'e' => { 'd' => 5, 'm' => 1 } },
        nil,
        { 'w' => 3, 'e' => nil })
    ]
  end

  let(:stats_by_minute) do
    [
      FakeLastSiteStat.new(2.minutes.ago.change(sec: 0), 5, nil),
      FakeLastSiteStat.new(1.minutes.ago.change(sec: 0), nil, 3)
    ]
  end

  let(:last_plays) do
    [
      FakeLastSitePlay.new(2.minutes.ago.change(sec: 0), 5, nil),
      FakeLastSitePlay.new(1.minutes.ago.change(sec: 0), nil, 3)
    ]
  end

  describe '.initialize' do
    it 'takes a video tag' do
      expect(presenter.resource).to eq site
    end

    context 'without options' do
      it 'has default options' do
        expect(presenter.options).to eq({ hours: 24, source: 'a' })
      end
    end

    context 'with options given' do
      let(:presenter) { described_class.new(site, 'hours' => 48) }

      it 'merge given options with default options' do
        expect(presenter.options).to eq({ hours: 48, source: 'a' })
      end
    end
  end

  describe '#browsers_and_platforms_stats' do
    before { expect(presenter).to receive(:_last_stats_by_hour) { stats_by_hour } }

    context 'source == "a"' do
      let(:expected_result) { { 'iex-win' => { count: 20, percent: 0.8 }, 'saf-osx' => { count: 5, percent: 0.2 } } }

      it { expect(presenter.browsers_and_platforms_stats).to eq expected_result }
    end

    context 'source == "w"' do
      let(:presenter) { described_class.new(site, source: 'w') }
      let(:expected_result) { { 'iex-win' => { count: 10, percent: 10/12.to_f }, 'saf-osx' => { count: 2, percent: 2/12.to_f } } }

      it { expect(presenter.browsers_and_platforms_stats).to eq expected_result }
    end

    context 'source == "e"' do
      let(:presenter) { described_class.new(site, source: 'e') }
      let(:expected_result) { { 'iex-win' => { count: 10, percent: 10/13.to_f }, 'saf-osx' => { count: 3, percent: 3/13.to_f } } }

      it { expect(presenter.browsers_and_platforms_stats).to eq expected_result }
    end
  end

  describe '#countries_stats' do
    before { expect(presenter).to receive(:_last_stats_by_hour) { stats_by_hour } }

    context 'source == "a"' do
      let(:expected_result) { { 'fr' => { count: 20, percent: 0.8 }, 'ch' => { count: 5, percent: 0.2 } } }

      it { expect(presenter.countries_stats).to eq expected_result }
    end

    context 'source == "w"' do
      let(:presenter) { described_class.new(site, source: 'w') }
      let(:expected_result) { { 'fr' => { count: 10, percent: 10/12.to_f }, 'ch' => { count: 2, percent: 2/12.to_f } } }

      it { expect(presenter.countries_stats).to eq expected_result }
    end

    context 'source == "e"' do
      let(:presenter) { described_class.new(site, source: 'e') }
      let(:expected_result) { { 'fr' => { count: 10, percent: 10/13.to_f }, 'ch' => { count: 3, percent: 3/13.to_f } } }

      it { expect(presenter.countries_stats).to eq expected_result }
    end
  end

  describe '#devices_stats' do
    before { expect(presenter).to receive(:_last_stats_by_hour) { stats_by_hour } }

    context 'source == "a"' do
      let(:expected_result) { { 'd' => { count: 20, percent: 0.8 }, 'm' => { count: 5, percent: 0.2 } } }

      it { expect(presenter.devices_stats).to eq expected_result }
    end

    context 'source == "w"' do
      let(:presenter) { described_class.new(site, source: 'w') }
      let(:expected_result) { { 'd' => { count: 10, percent: 10/13.to_f }, 'm' => { count: 3, percent: 3/13.to_f } } }

      it { expect(presenter.devices_stats).to eq expected_result }
    end

    context 'source == "e"' do
      let(:presenter) { described_class.new(site, source: 'e') }
      let(:expected_result) { { 'd' => { count: 10, percent: 10/12.to_f }, 'm' => { count: 2, percent: 2/12.to_f } } }

      it { expect(presenter.devices_stats).to eq expected_result }
    end
  end

  describe '#loads' do
    before { expect(presenter).to receive(:_last_stats_by_hour) { stats_by_hour } }

    context 'source == "a"' do
      it 'has 24 items' do
        expect(presenter.loads.size).to eq(24)
      end

      it 'has a value of 0 for missing hours' do
        expect(presenter.loads[0]).to eq [24.hours.ago.change(min: 0).to_i * 1000, 0]
      end

      it 'has right values for present hours' do
        expect(presenter.loads[22]).to eq [2.hours.ago.change(min: 0).to_i * 1000, 5]
      end
    end

    context 'source == "w"' do
      let(:presenter) { described_class.new(site, source: 'w') }

      it 'has 24 items' do
        expect(presenter.loads.size).to eq(24)
      end

      it 'has a value of 0 for missing hours' do
        expect(presenter.loads[0]).to eq [24.hours.ago.change(min: 0).to_i * 1000, 0]
      end

      it 'has right values for present hours' do
        expect(presenter.loads[22]).to eq [2.hours.ago.change(min: 0).to_i * 1000, 0]
      end
    end

    context 'source == "e"' do
      let(:presenter) { described_class.new(site, source: 'e') }

      it 'has 24 items' do
        expect(presenter.loads.size).to eq(24)
      end

      it 'has a value of 0 for missing hours' do
        expect(presenter.loads[0]).to eq [24.hours.ago.change(min: 0).to_i * 1000, 0]
      end

      it 'has right values for present hours' do
        expect(presenter.loads[22]).to eq [2.hours.ago.change(min: 0).to_i * 1000, 5]
      end
    end
  end

  describe '#plays' do
    before { expect(presenter).to receive(:_last_stats_by_hour) { stats_by_hour } }

    context 'source == "a"' do
      it 'has 24 items' do
        expect(presenter.plays.size).to eq(24)
      end

      it 'has a value of 0 for missing hours' do
        expect(presenter.plays[0]).to eq [24.hours.ago.change(min: 0).to_i * 1000, 0]
      end

      it 'has right values for present hours' do
        expect(presenter.plays[23]).to eq [1.hour.ago.change(min: 0).to_i * 1000, 3]
      end
    end

    context 'source == "w"' do
      let(:presenter) { described_class.new(site, source: 'w') }

      it 'has 24 items' do
        expect(presenter.plays.size).to eq(24)
      end

      it 'has a value of 0 for missing hours' do
        expect(presenter.plays[0]).to eq [24.hours.ago.change(min: 0).to_i * 1000, 0]
      end

      it 'has right values for present hours' do
        expect(presenter.plays[23]).to eq [1.hour.ago.change(min: 0).to_i * 1000, 3]
      end
    end

    context 'source == "e"' do
      let(:presenter) { described_class.new(site, source: 'e') }

      it 'has 24 items' do
        expect(presenter.plays.size).to eq(24)
      end

      it 'has a value of 0 for missing hours' do
        expect(presenter.plays[0]).to eq [24.hours.ago.change(min: 0).to_i * 1000, 0]
      end

      it 'has right values for present hours' do
        expect(presenter.plays[23]).to eq [1.hour.ago.change(min: 0).to_i * 1000, 0]
      end
    end
  end

  describe '#last_60_minutes_loads' do
    before { expect(presenter).to receive(:_last_stats_by_minute) { stats_by_minute } }

    it 'has 60 items' do
      expect(presenter.last_60_minutes_loads.size).to eq(60)
    end

    it 'has a value of 0 for missing minutes' do
      expect(presenter.last_60_minutes_loads[0]).to eq [59.minutes.ago.change(sec: 0).to_i * 1000, 0]
    end

    it 'has right values for present minutes' do
      expect(presenter.last_60_minutes_loads[57]).to eq [2.minutes.ago.change(sec: 0).to_i * 1000, 5]
    end
  end

  describe '#last_60_minutes_plays' do
    before { expect(presenter).to receive(:_last_stats_by_minute) { stats_by_minute } }

    it 'has 60 items' do
      expect(presenter.last_60_minutes_plays.size).to eq(60)
    end

    it 'has a value of 0 for missing minutes' do
      expect(presenter.last_60_minutes_plays[0]).to eq [59.minutes.ago.change(sec: 0).to_i * 1000, 0]
    end

    it 'has right values for present minutes' do
      expect(presenter.last_60_minutes_plays[58]).to eq [1.minute.ago.change(sec: 0).to_i * 1000, 3]
    end
  end

  describe '#last_modified' do
    context 'since option is not set' do
      before { expect(presenter).to receive(:_last_stats_by_hour) { stats_by_hour } }

      it 'returns the most recent updated_at for stats by hour' do
        expect(presenter.last_modified).to eq 1.hour.ago.change(min: 0)
      end
    end

    context 'since option is set' do
      before { expect(presenter).to receive(:_last_stats_by_minute) { stats_by_minute } }
      let(:presenter) { described_class.new(site, since: 1.hour.ago) }

      it 'returns the most recent updated_at for stats by minute' do
        expect(presenter.last_modified).to eq 1.minutes.ago.change(sec: 0)
      end
    end
  end

  describe '#_group_and_fill_missing_values_for_last_stats' do
    it 'fills missing minutes with 0' do
      stats = [[Time.utc(2013, 9, 11, 7).to_i * 1000, 13], [Time.utc(2013, 9, 11, 8).to_i * 1000, 42]]
      filled_stats = presenter.send(:_group_and_fill_missing_values_for_last_stats, stats, field: :lo, from: Time.utc(2013, 9, 11, 6), to: Time.utc(2013, 9, 11, 9), period: :hour)

      expect(filled_stats[0]).to eq [Time.utc(2013, 9, 11, 6).to_i * 1000, 0]
      expect(filled_stats[1]).to eq [Time.utc(2013, 9, 11, 7).to_i * 1000, 13]
      expect(filled_stats[2]).to eq [Time.utc(2013, 9, 11, 8).to_i * 1000, 42]
      expect(filled_stats[3]).to eq [Time.utc(2013, 9, 11, 9).to_i * 1000, 0]
    end
  end

end
