describe 'Stats', ->
  beforeEach ->
    MSVStats.period = new MSVStats.Models.Period() # 30 day
    @minute0  = new MSVStats.Models.Stat("mi":"#{MSVStats.Models.Period.today(s: 0).date.getTime()}","bp":{"and-and":3,"chr-osx":4,"chr-win":21,"fir-osx":2,"fir-win":16,"iex-win":12,"saf-ipa":0,"saf-iph":6,"saf-ipo":1,"saf-osx":5,"saf-win":1},"md":{"f":{"d":3,"m":0,"t":1},"h":{"d":11,"m":0,"t":1}},"pv":{"d":1,"e":0,"i":0,"m":8}, "t":"i626g0au","vv":{"d":1,"e":0,"i":1,"m":0})
    @minute1  = new MSVStats.Models.Stat("mi":"#{MSVStats.Models.Period.today(s: 0).subtract(m: 1).date.getTime()}","bp":{"and-and":3,"chr-osx":4,"chr-win":21,"fir-osx":2,"fir-win":16,"iex-win":12,"saf-ipa":0,"saf-iph":6,"saf-ipo":1,"saf-osx":5,"saf-win":1},"md":{"f":{"d":3,"m":0,"t":1},"h":{"d":11,"m":0,"t":1}},"pv":{"d":1,"e":0,"i":0,"m":8}, "t":"i626g0au","vv":{"d":1,"e":0,"i":1,"m":0})
    @minute5  = new MSVStats.Models.Stat("mi":"#{MSVStats.Models.Period.today(s: 0).subtract(m: 5).date.getTime()}","bp":{"and-and":3,"chr-osx":4,"chr-win":21,"fir-osx":2,"fir-win":16,"iex-win":12,"saf-ipa":0,"saf-iph":6,"saf-ipo":1,"saf-osx":5,"saf-win":1},"md":{"f":{"d":3,"m":0,"t":1},"h":{"d":11,"m":0,"t":1}},"pv":{"d":1,"e":0,"i":0,"m":8}, "t":"i626g0au","vv":{"d":1,"e":0,"i":1,"m":0})
    @minute59 = new MSVStats.Models.Stat("mi":"#{MSVStats.Models.Period.today(s: 0).subtract(m: 59).date.getTime()}","bp":{"and-and":3,"chr-osx":4,"chr-win":21,"fir-osx":2,"fir-win":16,"iex-win":12,"saf-ipa":0,"saf-iph":6,"saf-ipo":1,"saf-osx":5,"saf-win":1},"md":{"f":{"d":3,"m":0,"t":1},"h":{"d":11,"m":0,"t":1}},"pv":{"d":1,"e":0,"i":0,"m":8}, "t":"i626g0au","vv":{"d":1,"e":0,"i":1,"m":0})
    @minute60 = new MSVStats.Models.Stat("mi":"#{MSVStats.Models.Period.today(s: 0).subtract(m: 60).date.getTime()}","bp":{"and-and":3,"chr-osx":4,"chr-win":21,"fir-osx":2,"fir-win":16,"iex-win":12,"saf-ipa":0,"saf-iph":6,"saf-ipo":1,"saf-osx":5,"saf-win":1},"md":{"f":{"d":3,"m":0,"t":1},"h":{"d":11,"m":0,"t":1}},"pv":{"d":1,"e":0,"i":0,"m":8}, "t":"i626g0au","vv":{"d":1,"e":0,"i":1,"m":0})
    @hour1    = new MSVStats.Models.Stat("hi":"#{MSVStats.Models.Period.today(m: 0).subtract(h: 1).date.getTime()}","bp":{"and-and":5,"chr-osx":7,"chr-win":11,"fir-osx":3,"fir-win":17,"iex-win":1, "saf-ipa":2,"saf-iph":5,"saf-ipo":0,"saf-osx":0,"saf-win":0},"md":{"f":{"d":2,"m":1,"t":1},"h":{"d":2, "m":3,"t":0}},"pv":{"d":0,"e":1,"i":0,"m":13},"t":"i626g0au","vv":{"d":1,"e":0,"i":0,"m":1})
    @hour4    = new MSVStats.Models.Stat("hi":"#{MSVStats.Models.Period.today(m: 0).subtract(h: 4).date.getTime()}","bp":{"and-and":5,"chr-osx":7,"chr-win":11,"fir-osx":3,"fir-win":17,"iex-win":1, "saf-ipa":2,"saf-iph":5,"saf-ipo":0,"saf-osx":0,"saf-win":0},"md":{"f":{"d":2,"m":1,"t":1},"h":{"d":2, "m":3,"t":0}},"pv":{"d":0,"e":1,"i":0,"m":13},"t":"i626g0au","vv":{"d":1,"e":0,"i":0,"m":1})
    @hour23   = new MSVStats.Models.Stat("hi":"#{MSVStats.Models.Period.today(m: 0).subtract(h: 23).date.getTime()}","bp":{"and-and":5,"chr-osx":7,"chr-win":11,"fir-osx":3,"fir-win":17,"iex-win":1, "saf-ipa":2,"saf-iph":5,"saf-ipo":0,"saf-osx":0,"saf-win":0},"md":{"f":{"d":2,"m":1,"t":1},"h":{"d":2, "m":3,"t":0}},"pv":{"d":0,"e":1,"i":0,"m":13},"t":"i626g0au","vv":{"d":1,"e":0,"i":0,"m":1})
    @hour24   = new MSVStats.Models.Stat("hi":"#{MSVStats.Models.Period.today(m: 0).subtract(h: 24).date.getTime()}","bp":{"and-and":5,"chr-osx":7,"chr-win":11,"fir-osx":3,"fir-win":17,"iex-win":1, "saf-ipa":2,"saf-iph":5,"saf-ipo":0,"saf-osx":0,"saf-win":0},"md":{"f":{"d":2,"m":1,"t":1},"h":{"d":2, "m":3,"t":0}},"pv":{"d":0,"e":1,"i":0,"m":13},"t":"i626g0au","vv":{"d":1,"e":0,"i":0,"m":1})
    @day0     = new MSVStats.Models.Stat("di":"#{MSVStats.Models.Period.today(h: 0).date.getTime()}","bp":{"and-and":0,"chr-osx":5,"chr-win":14,"fir-osx":1,"fir-win":19,"iex-win":26,"saf-ipa":1,"saf-iph":0,"saf-ipo":1,"saf-osx":5,"saf-win":1},"md":{"f":{"d":0,"m":0,"t":0},"h":{"d":7, "m":3,"t":0}},"pv":{"d":0,"e":2,"i":1,"m":5}, "t":"i626g0au","vv":{"d":0,"e":0,"i":0,"m":7})
    @day1     = new MSVStats.Models.Stat("di":"#{MSVStats.Models.Period.today(h: 0).subtract(d: 1).date.getTime()}","bp":{"and-and":0,"chr-osx":5,"chr-win":14,"fir-osx":1,"fir-win":19,"iex-win":26,"saf-ipa":1,"saf-iph":0,"saf-ipo":1,"saf-osx":5,"saf-win":1},"md":{"f":{"d":5,"m":0,"t":0},"h":{"d":7, "m":3,"t":0}},"pv":{"d":0,"e":2,"i":1,"m":5}, "t":"i626g0au","vv":{"d":0,"e":0,"i":0,"m":7})
    @day6     = new MSVStats.Models.Stat("di":"#{MSVStats.Models.Period.today(h: 0).subtract(d: 6).date.getTime()}","bp":{"and-and":0,"chr-osx":5,"chr-win":14,"fir-osx":1,"fir-win":19,"iex-win":26,"saf-ipa":1,"saf-iph":0,"saf-ipo":1,"saf-osx":5,"saf-win":1},"md":{"f":{"d":5,"m":0,"t":0},"h":{"d":7, "m":3,"t":0}},"pv":{"d":0,"e":2,"i":1,"m":5}, "t":"i626g0au","vv":{"d":0,"e":0,"i":0,"m":7})
    @day29    = new MSVStats.Models.Stat("di":"#{MSVStats.Models.Period.today(h: 0).subtract(d: 29).date.getTime()}","bp":{"and-and":0,"chr-osx":5,"chr-win":14,"fir-osx":1,"fir-win":19,"iex-win":26,"saf-ipa":1,"saf-iph":0,"saf-ipo":1,"saf-osx":5,"saf-win":1},"md":{"f":{"d":5,"m":0,"t":0},"h":{"d":7, "m":3,"t":0}},"pv":{"d":0,"e":2,"i":1,"m":5}, "t":"i626g0au","vv":{"d":0,"e":0,"i":0,"m":7})
    @day30    = new MSVStats.Models.Stat("di":"#{MSVStats.Models.Period.today(h: 0).subtract(d: 30).date.getTime()}","bp":{"and-and":0,"chr-osx":5,"chr-win":14,"fir-osx":1,"fir-win":19,"iex-win":26,"saf-ipa":1,"saf-iph":0,"saf-ipo":1,"saf-osx":5,"saf-win":1},"md":{"f":{"d":5,"m":0,"t":0},"h":{"d":7, "m":3,"t":0}},"pv":{"d":0,"e":2,"i":1,"m":5}, "t":"i626g0au","vv":{"d":0,"e":0,"i":0,"m":7})
    @day31    = new MSVStats.Models.Stat("di":"#{MSVStats.Models.Period.today(h: 0).subtract(d: 31).date.getTime()}","bp":{"and-and":0,"chr-osx":5,"chr-win":14,"fir-osx":1,"fir-win":19,"iex-win":26,"saf-ipa":1,"saf-iph":0,"saf-ipo":1,"saf-osx":5,"saf-win":1},"md":{"f":{"d":5,"m":0,"t":0},"h":{"d":7, "m":3,"t":0}},"pv":{"d":0,"e":2,"i":1,"m":5}, "t":"i626g0au","vv":{"d":0,"e":0,"i":0,"m":7})
    @day43    = new MSVStats.Models.Stat("di":"#{MSVStats.Models.Period.today(h: 0).subtract(d: 43).date.getTime()}","bp":{"and-and":0,"chr-osx":5,"chr-win":14,"fir-osx":1,"fir-win":19,"iex-win":26,"saf-ipa":1,"saf-iph":0,"saf-ipo":1,"saf-osx":5,"saf-win":1},"md":{"f":{"d":5,"m":0,"t":0},"h":{"d":7, "m":3,"t":0}},"pv":{"d":0,"e":2,"i":1,"m":5}, "t":"i626g0au","vv":{"d":0,"e":0,"i":0,"m":7})
    MSVStats.stats = new MSVStats.Collections.Stats([
      @minute1, @minute5, @minute59, @minute60
      @hour1, @hour4, @hour23, @hour24
      @day1, @day6, @day29, @day30, @day31, @day43
    ])
    @period = MSVStats.period
    @stats  = MSVStats.stats

  describe 'forCurrentPeriod()', ->
    it 'return last 60 minutes with a null last minute ', ->
      @period.setPeriod('60 minutes')
      periodStats = @stats.forCurrentPeriod()
      expect(periodStats.length).toEqual(60)
      expect(_.first(periodStats).get('mi')).toEqual(@minute60.get('mi'))

    it 'return last 60 minutes with an existing last minute ', ->
      @period.setPeriod('60 minutes')
      MSVStats.stats.add(@minute0)
      periodStats = @stats.forCurrentPeriod()
      expect(periodStats.length).toEqual(60)
      expect(_.first(periodStats).get('mi')).toEqual(@minute59.get('mi'))
      expect(_.last(periodStats).get('mi')).toEqual(@minute0.get('mi'))

    it 'return last 24 hours', ->
      @period.setPeriod('24 hours')
      periodStats = @stats.forCurrentPeriod()
      expect(periodStats.length).toEqual(24)
      expect(_.first(periodStats).get('hi')).toEqual(@hour23.get('hi'))
      expect(_.last(periodStats).get('t')).toEqual(null)

    it 'return last 7 days', ->
      @period.setPeriod('7 days')
      periodStats = @stats.forCurrentPeriod()
      expect(periodStats.length).toEqual(7)
      expect(_.first(periodStats).get('di')).toEqual(@day6.get('di'))
      expect(_.last(periodStats).get('di')).toEqual(@day0.get('di'))

    it 'return last 30 days', ->
      @period.setPeriod('30 days')
      periodStats = @stats.forCurrentPeriod()
      expect(periodStats.length).toEqual(30)
      expect(_.first(periodStats).get('di')).toEqual(@day29.get('di'))
      expect(_.last(periodStats).get('di')).toEqual(@day0.get('di'))

    it 'return all days', ->
      @period.setPeriod('all days')
      periodStats = @stats.forCurrentPeriod()
      expect(periodStats.length).toEqual(44)
      expect(_.first(periodStats).get('di')).toEqual(@day43.get('di'))
      expect(_.last(periodStats).get('di')).toEqual(@day0.get('di'))

  describe 'mostRecentStatDate', ->
    it 'return most recent stat date', ->
      expect(@stats.mostRecentStatDate()).toEqual(@minute1.date())
    it 'return null when no stats', ->
      stats = new MSVStats.Collections.Stats()
      expect(stats.mostRecentStatDate()).toEqual(null)

  describe 'VVData', ->
    beforeEach ->
      @vvData = @stats.vvData()

    describe 'vv', ->
      it 'return well formed array with time for spline chart', ->
        expect(@vvData.vv.length).toEqual(30)
        expect(_.first(@vvData.vv)).toEqual([parseInt(@day29.get('di')), 7])

    describe 'pv', ->
      it 'return well formed array with time for spline chart', ->
        expect(@vvData.pv.length).toEqual(30)
        expect(_.last(@vvData.pv)).toEqual([parseInt(@day0.get('di')), 0])

    describe 'pvTotal()', ->
      it 'return total number of pv for the period', ->
        expect(@vvData.pvTotal()).toEqual(21)

    describe 'vvTotal()', ->
      it 'return total number of vv for the period', ->
        expect(@vvData.vvTotal()).toEqual(21)

  describe 'BPData', ->
    describe 'toArray()', ->
      it 'return well formed array for pie chart', ->
        bpData = @stats.bpData()
        expect(bpData.toArray()).toEqual([
          ['IE - Windows', 78]
          ['Firefox - Windows', 57]
          ['Chrome - Windows', 42]
          ['Safari - Macintosh', 15]
          ['Chrome - Macintosh', 15]
          ['Safari - Windows', 3]
          ['Safari - iPod', 3]
          ['Safari - iPad', 3]
          ['Firefox - Macintosh', 3]
        ])

    describe 'isEmpty', ->
      it 'returns true when all values == 0', ->
        MSVStats.stats = new MSVStats.Collections.Stats()
        expect(MSVStats.stats.bpData().isEmpty()).toEqual(true)

      it 'returns false when all values != 0', ->
        expect(@stats.bpData().isEmpty()).toEqual(false)

  describe 'MDData', ->
    beforeEach ->
      @mdData = @stats.mdData()

    it 'has data for Player mode part of pie chart', ->
      expect(@mdData.m).toEqual('HTML5':30, 'Flash': 15)

    it 'has data for Devise part of pie chart', ->
      expect(@mdData.d).toEqual(
        'HTML5 - Desktop': 21
        'HTML5 - Mobile': 9
        'HTML5 - Tablet': 0
        'Flash - Desktop': 15
        'Flash - Mobile': 0
        'Flash - Tablet': 0
      )

    describe 'toArray()', ->
      it 'has array data for Player mode part of pie chart', ->
        expect(@mdData.toArray('m')).toEqual([['HTML5', 30],['Flash', 15]])

      it 'has array data for Devise part of pie chart', ->
        expect(@mdData.toArray('d')).toEqual([
          ['HTML5 - Desktop', 21]
          ['HTML5 - Mobile', 9]
          ['Flash - Desktop', 15]
        ])

    describe 'isEmpty', ->
      it 'returns true when all values == 0', ->
        MSVStats.stats = new MSVStats.Collections.Stats()
        expect(MSVStats.stats.mdData().isEmpty()).toEqual(true)

      it 'returns false when all values != 0', ->
        expect(@stats.mdData().isEmpty()).toEqual(false)
