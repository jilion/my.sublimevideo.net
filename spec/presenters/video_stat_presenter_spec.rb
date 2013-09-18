require 'fast_spec_helper'

require 'presenters/video_stat_presenter'

VideoStat = Struct.new(:t, :bp, :co, :de, :lo, :st) unless defined?(VideoStat)
LastVideoStat = Struct.new(:t, :lo, :st) unless defined?(LastVideoStat)

describe VideoStatPresenter do
  let(:video_tag) { double('VideoTag') }
  let(:partial_params) { { hours: 48 } }
  let(:full_params) { { hours: 48, source: 'w' } }

  let(:presenter) { described_class.new(video_tag) }

  let(:stats_by_hour) do
    [
      VideoStat.new(
        2.hours.ago.change(min: 0).to_s,
        { 'w' => { 'saf-osx' => 1, 'iex-win' => 5 }, 'e' => { 'saf-osx' => 1, 'iex-win' => 5 } },
        { 'w' => { 'fr' => 5, 'ch' => 1 }, 'e' => { 'fr' => 5, 'ch' => 1 } },
        { 'w' => { 'd' => 5, 'm' => 1 }, 'e' => { 'd' => 5, 'm' => 1 } },
        { 'w' => nil, 'e' => 5 },
        nil),
      VideoStat.new(
        1.hour.ago.change(min: 0).to_s,
        { 'w' => { 'saf-osx' => 1, 'iex-win' => 5 }, 'e' => { 'saf-osx' => 2, 'iex-win' => 5 } },
        { 'w' => { 'fr' => 5, 'ch' => 1 }, 'e' => { 'fr' => 5, 'ch' => 2 } },
        { 'w' => { 'd' => 5, 'm' => 2 }, 'e' => { 'd' => 5, 'm' => 1 } },
        nil,
        { 'w' => 3, 'e' => nil })
    ]
  end

  let(:stats_by_minute) do
    [
      LastVideoStat.new(2.minutes.ago.change(sec: 0).to_s, 5, nil),
      LastVideoStat.new(1.minutes.ago.change(sec: 0).to_s, nil, 3)
    ]
  end

  describe '.initialize' do
    it 'takes a video tag' do
      presenter.video_tag.should eq video_tag
    end

    context 'without options' do
      it 'has default options' do
        presenter.options.should eq({ hours: 24, source: 'a' })
      end
    end

    context 'with options given' do
      let(:presenter) { described_class.new(video_tag, partial_params) }

      it 'merge given options with default options' do
        presenter.options.should eq({ hours: 48, source: 'a' })
      end
    end
  end

  describe '#last_stats_by_hour' do
    it 'delegates to VideoStat.last_hours_stats' do
      expect(VideoStat).to receive(:last_hours_stats).with(video_tag, presenter.options[:hours]) { stats_by_hour }

      presenter.last_stats_by_hour.should eq stats_by_hour
    end
  end

  describe '#last_stats_by_minute' do
    it 'delegates to VideoStat.last_stats' do
      expect(LastVideoStat).to receive(:last_stats).with(video_tag) { stats_by_minute }

      presenter.last_stats_by_minute.should eq stats_by_minute
    end
  end

  describe '#hourly_loads' do
    before { expect(presenter).to receive(:last_stats_by_hour) { stats_by_hour } }

    context 'source == "a"' do
      it 'has 24 items' do
        expect(presenter.hourly_loads).to have(24).items
      end

      it 'has a value of 0 for missing hours' do
        expect(presenter.hourly_loads[0]).to eq [24.hours.ago.change(min: 0).to_i * 1000, 0]
      end

      it 'has right values for present hours' do
        expect(presenter.hourly_loads[22]).to eq [2.hours.ago.change(min: 0).to_i * 1000, 5]
      end
    end

    context 'source == "w"' do
      let(:presenter) { described_class.new(video_tag, source: 'w') }

      it 'has 24 items' do
        expect(presenter.hourly_loads).to have(24).items
      end

      it 'has a value of 0 for missing hours' do
        expect(presenter.hourly_loads[0]).to eq [24.hours.ago.change(min: 0).to_i * 1000, 0]
      end

      it 'has right values for present hours' do
        expect(presenter.hourly_loads[22]).to eq [2.hours.ago.change(min: 0).to_i * 1000, 0]
      end
    end

    context 'source == "e"' do
      let(:presenter) { described_class.new(video_tag, source: 'e') }

      it 'has 24 items' do
        expect(presenter.hourly_loads).to have(24).items
      end

      it 'has a value of 0 for missing hours' do
        expect(presenter.hourly_loads[0]).to eq [24.hours.ago.change(min: 0).to_i * 1000, 0]
      end

      it 'has right values for present hours' do
        expect(presenter.hourly_loads[22]).to eq [2.hours.ago.change(min: 0).to_i * 1000, 5]
      end
    end
  end

  describe '#hourly_starts' do
    before { expect(presenter).to receive(:last_stats_by_hour) { stats_by_hour } }

    context 'source == "a"' do
      it 'has 24 items' do
        expect(presenter.hourly_starts).to have(24).items
      end

      it 'has a value of 0 for missing hours' do
        expect(presenter.hourly_starts[0]).to eq [24.hours.ago.change(min: 0).to_i * 1000, 0]
      end

      it 'has right values for present hours' do
        expect(presenter.hourly_starts[23]).to eq [1.hour.ago.change(min: 0).to_i * 1000, 3]
      end
    end

    context 'source == "w"' do
      let(:presenter) { described_class.new(video_tag, source: 'w') }

      it 'has 24 items' do
        expect(presenter.hourly_starts).to have(24).items
      end

      it 'has a value of 0 for missing hours' do
        expect(presenter.hourly_starts[0]).to eq [24.hours.ago.change(min: 0).to_i * 1000, 0]
      end

      it 'has right values for present hours' do
        expect(presenter.hourly_starts[23]).to eq [1.hour.ago.change(min: 0).to_i * 1000, 3]
      end
    end

    context 'source == "e"' do
      let(:presenter) { described_class.new(video_tag, source: 'e') }

      it 'has 24 items' do
        expect(presenter.hourly_starts).to have(24).items
      end

      it 'has a value of 0 for missing hours' do
        expect(presenter.hourly_starts[0]).to eq [24.hours.ago.change(min: 0).to_i * 1000, 0]
      end

      it 'has right values for present hours' do
        expect(presenter.hourly_starts[23]).to eq [1.hour.ago.change(min: 0).to_i * 1000, 0]
      end
    end
  end

  describe '#last_60_minutes_loads' do
    before { expect(presenter).to receive(:last_stats_by_minute) { stats_by_minute } }

    it 'has 60 items' do
      expect(presenter.last_60_minutes_loads).to have(60).items
    end

    it 'has a value of 0 for missing minutes' do
      expect(presenter.last_60_minutes_loads[0]).to eq [60.minutes.ago.change(sec: 0).to_i * 1000, 0]
    end

    it 'has right values for present minutes' do
      expect(presenter.last_60_minutes_loads[58]).to eq [2.minutes.ago.change(sec: 0).to_i * 1000, 5]
    end
  end

  describe '#last_60_minutes_starts' do
    before { expect(presenter).to receive(:last_stats_by_minute) { stats_by_minute } }

    it 'has 60 items' do
      expect(presenter.last_60_minutes_starts).to have(60).items
    end

    it 'has a value of 0 for missing minutes' do
      expect(presenter.last_60_minutes_starts[0]).to eq [60.minutes.ago.change(sec: 0).to_i * 1000, 0]
    end

    it 'has right values for present minutes' do
      expect(presenter.last_60_minutes_starts[59]).to eq [1.minute.ago.change(sec: 0).to_i * 1000, 3]
    end
  end

  describe '#_fill_missing_values_for_last_stats' do
    it 'fills missing minutes with 0' do
      stats = [[Time.utc(2013, 9, 11, 7).to_i * 1000, 13], [Time.utc(2013, 9, 11, 8).to_i * 1000, 42]]
      filled_stats = presenter.send(:_fill_missing_values_for_last_stats, stats, field: :lo, from: Time.utc(2013, 9, 11, 6), to: Time.utc(2013, 9, 11, 9), period: :hour)

      filled_stats[0].should eq [Time.utc(2013, 9, 11, 6).to_i * 1000, 0]
      filled_stats[1].should eq [Time.utc(2013, 9, 11, 7).to_i * 1000, 13]
      filled_stats[2].should eq [Time.utc(2013, 9, 11, 8).to_i * 1000, 42]
      filled_stats[3].should eq [Time.utc(2013, 9, 11, 9).to_i * 1000, 0]
    end
  end

  describe '#browsers_and_platforms_stats' do
    before { expect(presenter).to receive(:last_stats_by_hour) { stats_by_hour } }

    context 'source == "a"' do
      let(:expected_result) { { 'iex-win' => { count: 20, percent: 0.8 }, 'saf-osx' => { count: 5, percent: 0.2 } } }

      it { expect(presenter.browsers_and_platforms_stats).to eq expected_result }
    end

    context 'source == "w"' do
      let(:presenter) { described_class.new(video_tag, source: 'w') }
      let(:expected_result) { { 'iex-win' => { count: 10, percent: 10/12.to_f }, 'saf-osx' => { count: 2, percent: 2/12.to_f } } }

      it { expect(presenter.browsers_and_platforms_stats).to eq expected_result }
    end

    context 'source == "e"' do
      let(:presenter) { described_class.new(video_tag, source: 'e') }
      let(:expected_result) { { 'iex-win' => { count: 10, percent: 10/13.to_f }, 'saf-osx' => { count: 3, percent: 3/13.to_f } } }

      it { expect(presenter.browsers_and_platforms_stats).to eq expected_result }
    end
  end

  describe '#countries_stats' do
    before { expect(presenter).to receive(:last_stats_by_hour) { stats_by_hour } }

    context 'source == "a"' do
      let(:expected_result) { { 'fr' => { count: 20, percent: 0.8 }, 'ch' => { count: 5, percent: 0.2 } } }

      it { expect(presenter.countries_stats).to eq expected_result }
    end

    context 'source == "w"' do
      let(:presenter) { described_class.new(video_tag, source: 'w') }
      let(:expected_result) { { 'fr' => { count: 10, percent: 10/12.to_f }, 'ch' => { count: 2, percent: 2/12.to_f } } }

      it { expect(presenter.countries_stats).to eq expected_result }
    end

    context 'source == "e"' do
      let(:presenter) { described_class.new(video_tag, source: 'e') }
      let(:expected_result) { { 'fr' => { count: 10, percent: 10/13.to_f }, 'ch' => { count: 3, percent: 3/13.to_f } } }

      it { expect(presenter.countries_stats).to eq expected_result }
    end
  end

  describe '#devices_stats' do
    before { expect(presenter).to receive(:last_stats_by_hour) { stats_by_hour } }

    context 'source == "a"' do
      let(:expected_result) { { 'd' => { count: 20, percent: 0.8 }, 'm' => { count: 5, percent: 0.2 } } }

      it { expect(presenter.devices_stats).to eq expected_result }
    end

    context 'source == "w"' do
      let(:presenter) { described_class.new(video_tag, source: 'w') }
      let(:expected_result) { { 'd' => { count: 10, percent: 10/13.to_f }, 'm' => { count: 3, percent: 3/13.to_f } } }

      it { expect(presenter.devices_stats).to eq expected_result }
    end

    context 'source == "e"' do
      let(:presenter) { described_class.new(video_tag, source: 'e') }
      let(:expected_result) { { 'd' => { count: 10, percent: 10/12.to_f }, 'm' => { count: 2, percent: 2/12.to_f } } }

      it { expect(presenter.devices_stats).to eq expected_result }
    end
  end
end
