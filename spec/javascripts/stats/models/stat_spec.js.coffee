describe 'Stat', ->
  beforeEach ->
    @stat = new MSVStats.Models.Stat(_.first(minutesStats))

  describe 'time()', ->
    it 'returns javascript stat time', ->
      expect(@stat.time()).toEqual(1316593200000)

  describe 'date()', ->
    it 'returns stat date', ->
      expect(@stat.date()).toEqual(new Date(1316593200000))

describe 'Stats', ->
  beforeEach ->
    @stats = new MSVStats.Collections.Stats()
    @stats.reset(minutesStats)

  it 'returns array of vv', ->
    expect(@stats.pluck('vv').length).toEqual(60)

  describe 'pvTotal()', ->
    it 'returns sum of all pv', ->
      expect(@stats.pvTotal()).toEqual(585)

  describe 'vvTotal()', ->
    it 'returns sum of all vv', ->
      expect(@stats.vvTotal()).toEqual(309)

describe 'StatsDays', ->
  beforeEach ->
    MSVStats.period    = new MSVStats.Models.Period()
    MSVStats.statsDays = new MSVStats.Collections.StatsDays()
    @stats = MSVStats.statsDays
    @stats.reset(daysStats)

  describe 'vvTotal(dateRange)', ->
    it 'returns period dateRange vv sum', ->
      MSVStats.period.setPeriod type: 'days'
      expect(@stats.vvTotal()).toEqual(332640)

    it 'returns custom period dateRange vv sum', ->
      dateRange = [
        @stats.at(@stats.length - 30).time()
        @stats.last().time()
      ]
      expect(@stats.vvTotal(dateRange)).toEqual(259200)

  describe 'customPluck(attr, firstIndex)', ->
    it 'returns [] when no stats', ->
      @stats.reset()
      expect(@stats.customPluck('vv', -30)).toEqual([])

    it 'returns only last 30 vv when no stats', ->
      expect(@stats.customPluck('vv', -30).length).toEqual(30)


  describe 'BPData', ->
    beforeEach ->
      MSVStats.period.setPeriod type: 'days'
      @bpData = @stats.bpData()

    it 'returns aggregated BPData', ->
      expect(@bpData.bp).toEqual
       'and-and': 165600
       'chr-osx': 299520
       'chr-win': 1213920
       'fir-osx': 115200
       'fir-win': 663840
       'iex-win': 760320
       'saf-ipa': 128160
       'saf-iph': 168480
       'saf-ipo': 33120
       'saf-osx': 227520
       'saf-win': 21600

    it 'returns aggregated with custom dates range', ->
      MSVStats.period.setPeriod type: 'days', startIndex: -30, endIndex: -1
      @bpData = @stats.bpData()
      expect(@bpData.bp).toEqual
       'and-and': 139680
       'chr-osx': 264960
       'chr-win': 923040
       'fir-osx': 92160
       'fir-win': 545760
       'iex-win': 571680
       'saf-ipa': 106560
       'saf-iph': 131040
       'saf-ipo': 23040
       'saf-osx': 177120
       'saf-win': 15840

    it 'sets total', ->
      expect(@bpData.total).toEqual(3797280)

    describe 'toArray()', ->
      it 'return well formed array for view', ->
        expect(@bpData.toArray()).toEqual [
          [ 'chr-win', 1213920 ]
          [ 'iex-win', 760320 ]
          [ 'fir-win', 663840 ]
          [ 'chr-osx', 299520 ]
          [ 'saf-osx', 227520 ]
          [ 'saf-iph', 168480 ]
          [ 'and-and', 165600 ]
          [ 'saf-ipa', 128160 ]
          [ 'fir-osx', 115200 ]
          [ 'saf-ipo', 33120 ]
          [ 'saf-win', 21600 ]
        ]

    describe 'percentage()', ->
      it 'return percentage based on total', ->
        expect(@stats.bpData().percentage(1213920)).toEqual('31.97')

    describe 'isEmpty', ->
      it 'returns true when total == 0', ->
        MSVStats.stats = new MSVStats.Collections.Stats()
        expect(MSVStats.stats.bpData().isEmpty()).toEqual(true)

      it 'returns false when total != 0', ->
        expect(@stats.bpData().isEmpty()).toEqual(false)

  describe 'MDData', ->
    beforeEach ->
      MSVStats.period.setPeriod type: 'days'
      @mdData = @stats.mdData()

    it 'set media HTML5 total', ->
      expect(@mdData.mh).toEqual(433440)

    it 'set media Flash total', ->
      expect(@mdData.mf).toEqual(141120)

    it 'set HTML5 devise totals', ->
      expect(@mdData.dh).toEqual
        'Desktop': 257760
        'Mobile':  115200
        'Tablet':  60480

    it 'set Flash devise totals', ->
      expect(@mdData.df).toEqual
        'Desktop': 141120
        'Mobile': 0
        'Tablet': 0

    describe 'toArray()', ->
      it 'has array data for HTML5 devise totals', ->
        expect(@mdData.toArray('dh')).toEqual [
          ['Desktop', 257760]
          ['Mobile',  115200]
          ['Tablet',   60480]
        ]

      it 'has array data for Flash devise totals', ->
        expect(@mdData.toArray('df')).toEqual [
          ['Desktop', 141120]
        ]

    describe 'isEmpty', ->
      it 'returns true when total == 0', ->
        MSVStats.stats = new MSVStats.Collections.Stats()
        expect(MSVStats.stats.mdData().isEmpty()).toEqual(true)

      it 'returns false when total != 0', ->
        expect(@stats.mdData().isEmpty()).toEqual(false)
