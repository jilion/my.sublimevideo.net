describe 'Stats', ->
  beforeEach ->
    MSVStats.period = new MSVStats.Models.Period() # 30 day
    @minute0  = new MSVStats.Models.Stat("mi":"#{new Date().set(second: 0, millisecond: 0).getTime()}","bp":{"and-and":3,"chr-osx":4,"chr-win":21,"fir-osx":2,"fir-win":16,"iex-win":12,"saf-ipa":0,"saf-iph":6,"saf-ipo":1,"saf-osx":5,"saf-win":1},"md":{"f":{"d":3,"m":0,"t":1},"h":{"d":11,"m":0,"t":1}},"pv":{"d":1,"e":0,"i":0,"m":8}, "t":"i626g0au","vv":{"d":1,"e":0,"i":1,"m":0})
    @minute1  = new MSVStats.Models.Stat("mi":"#{new Date().add(minutes: -1).set(second: 0, millisecond: 0).getTime()}","bp":{"and-and":3,"chr-osx":4,"chr-win":21,"fir-osx":2,"fir-win":16,"iex-win":12,"saf-ipa":0,"saf-iph":6,"saf-ipo":1,"saf-osx":5,"saf-win":1},"md":{"f":{"d":3,"m":0,"t":1},"h":{"d":11,"m":0,"t":1}},"pv":{"d":1,"e":0,"i":0,"m":8}, "t":"i626g0au","vv":{"d":1,"e":0,"i":1,"m":0})
    @minute5  = new MSVStats.Models.Stat("mi":"#{new Date().add(minutes: -5).set(second: 0, millisecond: 0).getTime()}","bp":{"and-and":3,"chr-osx":4,"chr-win":21,"fir-osx":2,"fir-win":16,"iex-win":12,"saf-ipa":0,"saf-iph":6,"saf-ipo":1,"saf-osx":5,"saf-win":1},"md":{"f":{"d":3,"m":0,"t":1},"h":{"d":11,"m":0,"t":1}},"pv":{"d":1,"e":0,"i":0,"m":8}, "t":"i626g0au","vv":{"d":1,"e":0,"i":1,"m":0})
    @minute59 = new MSVStats.Models.Stat("mi":"#{new Date().add(minutes: -59).set(second: 0, millisecond: 0).getTime()}","bp":{"and-and":3,"chr-osx":4,"chr-win":21,"fir-osx":2,"fir-win":16,"iex-win":12,"saf-ipa":0,"saf-iph":6,"saf-ipo":1,"saf-osx":5,"saf-win":1},"md":{"f":{"d":3,"m":0,"t":1},"h":{"d":11,"m":0,"t":1}},"pv":{"d":1,"e":0,"i":0,"m":8}, "t":"i626g0au","vv":{"d":1,"e":0,"i":1,"m":0})
    @minute60 = new MSVStats.Models.Stat("mi":"#{new Date().add(minutes: -60).set(second: 0, millisecond: 0).getTime()}","bp":{"and-and":3,"chr-osx":4,"chr-win":21,"fir-osx":2,"fir-win":16,"iex-win":12,"saf-ipa":0,"saf-iph":6,"saf-ipo":1,"saf-osx":5,"saf-win":1},"md":{"f":{"d":3,"m":0,"t":1},"h":{"d":11,"m":0,"t":1}},"pv":{"d":1,"e":0,"i":0,"m":8}, "t":"i626g0au","vv":{"d":1,"e":0,"i":1,"m":0})
    @hour1    = new MSVStats.Models.Stat("hi":"#{new Date().add(hours: -1).set(minute: 0, second: 0, millisecond: 0).getTime()}","bp":{"and-and":5,"chr-osx":7,"chr-win":11,"fir-osx":3,"fir-win":17,"iex-win":1, "saf-ipa":2,"saf-iph":5,"saf-ipo":0,"saf-osx":0,"saf-win":0},"md":{"f":{"d":2,"m":1,"t":1},"h":{"d":2, "m":3,"t":0}},"pv":{"d":0,"e":1,"i":0,"m":13},"t":"i626g0au","vv":{"d":1,"e":0,"i":0,"m":1})
    @hour4    = new MSVStats.Models.Stat("hi":"#{new Date().add(hours: -4).set(minute: 0, second: 0, millisecond: 0).getTime()}","bp":{"and-and":5,"chr-osx":7,"chr-win":11,"fir-osx":3,"fir-win":17,"iex-win":1, "saf-ipa":2,"saf-iph":5,"saf-ipo":0,"saf-osx":0,"saf-win":0},"md":{"f":{"d":2,"m":1,"t":1},"h":{"d":2, "m":3,"t":0}},"pv":{"d":0,"e":1,"i":0,"m":13},"t":"i626g0au","vv":{"d":1,"e":0,"i":0,"m":1})
    @hour23   = new MSVStats.Models.Stat("hi":"#{new Date().add(hours: -23).set(minute: 0, second: 0, millisecond: 0).getTime()}","bp":{"and-and":5,"chr-osx":7,"chr-win":11,"fir-osx":3,"fir-win":17,"iex-win":1, "saf-ipa":2,"saf-iph":5,"saf-ipo":0,"saf-osx":0,"saf-win":0},"md":{"f":{"d":2,"m":1,"t":1},"h":{"d":2, "m":3,"t":0}},"pv":{"d":0,"e":1,"i":0,"m":13},"t":"i626g0au","vv":{"d":1,"e":0,"i":0,"m":1})
    @hour24   = new MSVStats.Models.Stat("hi":"#{new Date().add(hours: -24).set(minute: 0, second: 0, millisecond: 0).getTime()}","bp":{"and-and":5,"chr-osx":7,"chr-win":11,"fir-osx":3,"fir-win":17,"iex-win":1, "saf-ipa":2,"saf-iph":5,"saf-ipo":0,"saf-osx":0,"saf-win":0},"md":{"f":{"d":2,"m":1,"t":1},"h":{"d":2, "m":3,"t":0}},"pv":{"d":0,"e":1,"i":0,"m":13},"t":"i626g0au","vv":{"d":1,"e":0,"i":0,"m":1})
    @day0     = new MSVStats.Models.Stat("di":"#{new Date().set(hour: 0, minute: 0, second: 0, millisecond: 0).getTime()}","bp":{"and-and":0,"chr-osx":5,"chr-win":14,"fir-osx":1,"fir-win":19,"iex-win":26,"saf-ipa":1,"saf-iph":0,"saf-ipo":1,"saf-osx":5,"saf-win":1},"md":{"f":{"d":0,"m":0,"t":0},"h":{"d":7, "m":3,"t":0}},"pv":{"d":0,"e":2,"i":1,"m":5}, "t":"i626g0au","vv":{"d":0,"e":0,"i":0,"m":7})
    @day1     = new MSVStats.Models.Stat("di":"#{new Date().add(days: -1).set(hour: 0, minute: 0, second: 0, millisecond: 0).getTime()}","bp":{"and-and":0,"chr-osx":5,"chr-win":14,"fir-osx":1,"fir-win":19,"iex-win":26,"saf-ipa":1,"saf-iph":0,"saf-ipo":1,"saf-osx":5,"saf-win":1},"md":{"f":{"d":0,"m":0,"t":0},"h":{"d":7, "m":3,"t":0}},"pv":{"d":0,"e":2,"i":1,"m":5}, "t":"i626g0au","vv":{"d":0,"e":0,"i":0,"m":7})
    @day5     = new MSVStats.Models.Stat("di":"#{new Date().add(days: -5).set(hour: 0, minute: 0, second: 0, millisecond: 0).getTime()}","bp":{"and-and":0,"chr-osx":5,"chr-win":14,"fir-osx":1,"fir-win":19,"iex-win":26,"saf-ipa":1,"saf-iph":0,"saf-ipo":1,"saf-osx":5,"saf-win":1},"md":{"f":{"d":0,"m":0,"t":0},"h":{"d":7, "m":3,"t":0}},"pv":{"d":0,"e":2,"i":1,"m":5}, "t":"i626g0au","vv":{"d":0,"e":0,"i":0,"m":7})
    @day29    = new MSVStats.Models.Stat("di":"#{new Date().add(days: -29).set(hour: 0, minute: 0, second: 0, millisecond: 0).getTime()}","bp":{"and-and":0,"chr-osx":5,"chr-win":14,"fir-osx":1,"fir-win":19,"iex-win":26,"saf-ipa":1,"saf-iph":0,"saf-ipo":1,"saf-osx":5,"saf-win":1},"md":{"f":{"d":0,"m":0,"t":0},"h":{"d":7, "m":3,"t":0}},"pv":{"d":0,"e":2,"i":1,"m":5}, "t":"i626g0au","vv":{"d":0,"e":0,"i":0,"m":7})
    @day30    = new MSVStats.Models.Stat("di":"#{new Date().add(days: -30).set(hour: 0, minute: 0, second: 0, millisecond: 0).getTime()}","bp":{"and-and":0,"chr-osx":5,"chr-win":14,"fir-osx":1,"fir-win":19,"iex-win":26,"saf-ipa":1,"saf-iph":0,"saf-ipo":1,"saf-osx":5,"saf-win":1},"md":{"f":{"d":0,"m":0,"t":0},"h":{"d":7, "m":3,"t":0}},"pv":{"d":0,"e":2,"i":1,"m":5}, "t":"i626g0au","vv":{"d":0,"e":0,"i":0,"m":7})
    @day31    = new MSVStats.Models.Stat("di":"#{new Date().add(days: -31).set(hour: 0, minute: 0, second: 0, millisecond: 0).getTime()}","bp":{"and-and":0,"chr-osx":5,"chr-win":14,"fir-osx":1,"fir-win":19,"iex-win":26,"saf-ipa":1,"saf-iph":0,"saf-ipo":1,"saf-osx":5,"saf-win":1},"md":{"f":{"d":0,"m":0,"t":0},"h":{"d":7, "m":3,"t":0}},"pv":{"d":0,"e":2,"i":1,"m":5}, "t":"i626g0au","vv":{"d":0,"e":0,"i":0,"m":7})
    @day43    = new MSVStats.Models.Stat("di":"#{new Date().add(days: -43).set(hour: 0, minute: 0, second: 0, millisecond: 0).getTime()}","bp":{"and-and":0,"chr-osx":5,"chr-win":14,"fir-osx":1,"fir-win":19,"iex-win":26,"saf-ipa":1,"saf-iph":0,"saf-ipo":1,"saf-osx":5,"saf-win":1},"md":{"f":{"d":0,"m":0,"t":0},"h":{"d":7, "m":3,"t":0}},"pv":{"d":0,"e":2,"i":1,"m":5}, "t":"i626g0au","vv":{"d":0,"e":0,"i":0,"m":7})
    MSVStats.stats = new MSVStats.Collections.Stats([
      @minute1, @minute5, @minute59, @minute60, @minute61
      @hour1, @hour4, @hour23, @hour24, @hour25
      @day1, @day5, @day29, @day30, @day31, @day43
    ])
    @period = MSVStats.period
    @stats  = MSVStats.stats

  describe 'forCurrentPeriod()', ->
    it 'return last 60 minutes with a null last minute ', ->
      @period.setPeriod('60 minutes')
      expect(@stats.forCurrentPeriod().length).toEqual(60)
      expect(_.first(@stats.forCurrentPeriod()).get('mi')).toEqual(@minute60.get('mi'))

    it 'return last 60 minutes with an existing last minute ', ->
      @period.setPeriod('60 minutes')
      MSVStats.stats.add(@minute0)
      expect(@stats.forCurrentPeriod().length).toEqual(60)
      expect(_.first(@stats.forCurrentPeriod()).get('mi')).toEqual(@minute59.get('mi'))
      expect(_.last(@stats.forCurrentPeriod()).get('mi')).toEqual(@minute0.get('mi'))

    it 'return last 24 hours', ->
      @period.setPeriod('24 hours')
      expect(@stats.forCurrentPeriod().length).toEqual(24)
      expect(_.first(@stats.forCurrentPeriod()).get('hi')).toEqual(@hour23.get('hi'))
      expect(_.last(@stats.forCurrentPeriod()).get('t')).toEqual(null)

    it 'return last 30 days', ->
      @period.setPeriod('30 days')
      expect(@stats.forCurrentPeriod().length).toEqual(30)
      expect(_.first(@stats.forCurrentPeriod()).get('di')).toEqual(@day29.get('di'))
      expect(_.last(@stats.forCurrentPeriod()).get('di')).toEqual(@day0.get('di'))

    it 'return all days', ->
      @period.setPeriod('all days')
      expect(@stats.forCurrentPeriod().length).toEqual(44)
      expect(_.first(@stats.forCurrentPeriod()).get('di')).toEqual(@day43.get('di'))
      expect(_.last(@stats.forCurrentPeriod()).get('di')).toEqual(@day0.get('di'))


  describe 'BPData', ->
    describe 'toArray()', ->
      it 'return well formed array for pie chart', ->
        bpData = @stats.bpData()
        expect(bpData.toArray()).toEqual([
          ['IE - Windows', 72]
          ['Chrome - Windows', 62]
          ['Firefox - Windows', 38]
          ['Safari - Macintosh', 8]
          ['Firefox - Macintosh', 8]
          ['Chrome - Macintosh', 8]
          ['Safari - Windows', 3]
          ['Safari - iPad', 2]
          ['Safari - iPod', 1]
          ['Safari - iPhone', 1]
          ['Android - Android', 1]
        ])

  describe 'MDData', ->
    beforeEach ->
      @mdData = @stats.mdData()

    it 'has data for Player mode part of pie chart', ->
      expect(@mdData.m).toEqual('HTML5':21, 'Flash': 5)

    it 'has data for Devise part of pie chart', ->
      expect(@mdData.d).toEqual(
        'HTML5 - Desktop': 13
        'HTML5 - Mobile': 7
        'HTML5 - Tablet': 1
        'Flash - Desktop': 4
        'Flash - Mobile': 1
        'Flash - Tablet': 0
      )

    describe 'toArray()', ->
      it 'has array data for Player mode part of pie chart', ->
        expect(@mdData.toArray('m')).toEqual([['HTML5', 21], ['Flash', 5]])

      it 'has array data for Devise part of pie chart', ->
        expect(@mdData.toArray('d')).toEqual([
          ['HTML5 - Desktop', 13]
          ['HTML5 - Mobile', 7]
          ['HTML5 - Tablet', 1]
          ['Flash - Desktop', 4]
          ['Flash - Mobile', 1]
        ])
