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
    MSVStats.period = new MSVStats.Models.Period()
    @stats = new MSVStats.Collections.StatsDays()
    @stats.reset(daysStats)

  describe 'vvTotal(dateRange)', ->
    it 'returns period dateRange vv sum', ->
      MSVStats.period.setPeriod
        type:      'days'
        startTime: @stats.first().time()
        endTime:   @stats.last().time()
      expect(@stats.vvTotal()).toEqual(332640)

    it 'returns custom period dateRange vv sum', ->
      console.log @stats.length
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




  # describe 'forCurrentPeriod()', ->
  #   it 'return last 60 minutes with a null last minute ', ->
  #     @period.setPeriod('60 minutes')
  #     periodStats = @stats.forCurrentPeriod()
  #     expect(periodStats.length).toEqual(60)
  #     expect(_.first(periodStats).get('mi')).toEqual(@minute60.get('mi'))
  #
  #   it 'return last 60 minutes with an existing last minute ', ->
  #     @period.setPeriod('60 minutes')
  #     MSVStats.stats.add(@minute0)
  #     periodStats = @stats.forCurrentPeriod()
  #     expect(periodStats.length).toEqual(60)
  #     expect(_.first(periodStats).get('mi')).toEqual(@minute59.get('mi'))
  #     expect(_.last(periodStats).get('mi')).toEqual(@minute0.get('mi'))
  #
  #   it 'return last 24 hours', ->
  #     @period.setPeriod('24 hours')
  #     periodStats = @stats.forCurrentPeriod()
  #     expect(periodStats.length).toEqual(24)
  #     expect(_.first(periodStats).get('hi')).toEqual(@hour23.get('hi'))
  #     expect(_.last(periodStats).get('t')).toEqual(null)
  #
  #   it 'return last 7 days', ->
  #     @period.setPeriod('7 days')
  #     periodStats = @stats.forCurrentPeriod()
  #     expect(periodStats.length).toEqual(7)
  #     expect(_.first(periodStats).get('di')).toEqual(@day6.get('di'))
  #     expect(_.last(periodStats).get('di')).toEqual(@day0.get('di'))
  #
  #   it 'return last 30 days', ->
  #     @period.setPeriod('30 days')
  #     periodStats = @stats.forCurrentPeriod()
  #     expect(periodStats.length).toEqual(30)
  #     expect(_.first(periodStats).get('di')).toEqual(@day29.get('di'))
  #     expect(_.last(periodStats).get('di')).toEqual(@day0.get('di'))
  #
  #   it 'return all days', ->
  #     @period.setPeriod('all days')
  #     periodStats = @stats.forCurrentPeriod()
  #     expect(periodStats.length).toEqual(44)
  #     expect(_.first(periodStats).get('di')).toEqual(@day43.get('di'))
  #     expect(_.last(periodStats).get('di')).toEqual(@day0.get('di'))
  #
  #   it 'return custom days', ->
  #     @period.setCustomPeriod(@day6.get('di'), @day31.get('di'))
  #     console.log @stats.forCurrentPeriodType()
  #     periodStats = @stats.forCurrentPeriod()
  #     expect(periodStats.length).toEqual(31 - 6 + 1)
  #     expect(_.first(periodStats).get('di')).toEqual(@day31.get('di'))
  #     expect(_.last(periodStats).get('di')).toEqual(@day6.get('di'))
  #
  # describe 'lastStatsDate', ->
  #   it 'return most recent stat date', ->
  #     expect(@stats.lastStatsDate()).toEqual(@minute1.date())
  #   it 'return null when no stats', ->
  #     stats = new MSVStats.Collections.Stats()
  #     expect(stats.lastStatsDate()).toEqual(null)
  #
  # describe 'firstStatsDate', ->
  #   it 'return first exsiting stat date', ->
  #     expect(@stats.firstStatsDate()).toEqual(@day43.date())
  #   it 'return null when no stats', ->
  #     stats = new MSVStats.Collections.Stats()
  #     expect(stats.firstStatsDate()).toEqual(null)
  #
  # describe 'VVData', ->
  #   beforeEach ->
  #     @vvData = @stats.vvData()
  #
  #   describe 'vv', ->
  #     it 'return well formed array with time for spline chart', ->
  #       expect(@vvData.vv.length).toEqual(30)
  #       expect(_.first(@vvData.vv)).toEqual(7)
  #
  #   describe 'pv', ->
  #     it 'return well formed array with time for spline chart', ->
  #       expect(@vvData.pv.length).toEqual(30)
  #       expect(_.last(@vvData.pv)).toEqual(0)
  #
  #   describe 'pvTotal()', ->
  #     it 'return total number of pv for the period', ->
  #       expect(@vvData.pvTotal()).toEqual(21)
  #
  #   describe 'vvTotal()', ->
  #     it 'return total number of vv for the period', ->
  #       expect(@vvData.vvTotal()).toEqual(21)
  #
  # describe 'BPData', ->
  #   describe 'toArray()', ->
  #     it 'return well formed array for pie chart', ->
  #       bpData = @stats.bpData()
  #       expect(bpData.toArray()).toEqual([
  #         ['IE - Windows', 78]
  #         ['Firefox - Windows', 57]
  #         ['Chrome - Windows', 42]
  #         ['Safari - Macintosh', 15]
  #         ['Chrome - Macintosh', 15]
  #         ['Safari - Windows', 3]
  #         ['Safari - iPod', 3]
  #         ['Safari - iPad', 3]
  #         ['Firefox - Macintosh', 3]
  #       ])
  #
  #   describe 'isEmpty', ->
  #     it 'returns true when all values == 0', ->
  #       MSVStats.stats = new MSVStats.Collections.Stats()
  #       expect(MSVStats.stats.bpData().isEmpty()).toEqual(true)
  #
  #     it 'returns false when all values != 0', ->
  #       expect(@stats.bpData().isEmpty()).toEqual(false)
  #
  # describe 'MDData', ->
  #   beforeEach ->
  #     @mdData = @stats.mdData()
  #
  #   it 'has data for Player mode part of pie chart', ->
  #     expect(@mdData.m).toEqual('HTML5':30, 'Flash': 15)
  #
  #   it 'has data for Devise part of pie chart', ->
  #     expect(@mdData.d).toEqual(
  #       'HTML5 - Desktop': 21
  #       'HTML5 - Mobile': 9
  #       'HTML5 - Tablet': 0
  #       'Flash - Desktop': 15
  #       'Flash - Mobile': 0
  #       'Flash - Tablet': 0
  #     )
  #
  #   describe 'toArray()', ->
  #     it 'has array data for Player mode part of pie chart', ->
  #       expect(@mdData.toArray('m')).toEqual([['HTML5', 30],['Flash', 15]])
  #
  #     it 'has array data for Devise part of pie chart', ->
  #       expect(@mdData.toArray('d')).toEqual([
  #         ['HTML5 - Desktop', 21]
  #         ['HTML5 - Mobile', 9]
  #         ['Flash - Desktop', 15]
  #       ])
  #
  #   describe 'isEmpty', ->
  #     it 'returns true when all values == 0', ->
  #       MSVStats.stats = new MSVStats.Collections.Stats()
  #       expect(MSVStats.stats.mdData().isEmpty()).toEqual(true)
  #
  #     it 'returns false when all values != 0', ->
  #       expect(@stats.mdData().isEmpty()).toEqual(false)
