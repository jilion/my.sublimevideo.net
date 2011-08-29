describe 'Stats', ->
  beforeEach ->
    MSVStats.period = new MSVStats.Models.Period() # 30 day
    MSVStats.stats  = new MSVStats.Collections.Stats([
      {"m":"2011-08-29T11:44:00+00:00","bp":{"and-and":3,"chr-osx":4,"chr-win":21,"fir-osx":2,"fir-win":16,"iex-win":12,"saf-ipa":0,"saf-iph":6,"saf-ipo":1,"saf-osx":5,"saf-win":1},"md":{"f":{"d":3,"m":0,"t":1},"h":{"d":11,"m":0,"t":1}},"pv":{"d":1,"e":0,"i":0,"m":8}, "t":"i626g0au","vv":{"d":1,"e":0,"i":1,"m":0}}
      {"m":"2011-08-29T11:45:00+00:00","bp":{"and-and":2,"chr-osx":9,"chr-win":18,"fir-osx":3,"fir-win":16,"iex-win":10,"saf-ipa":4,"saf-iph":1,"saf-ipo":0,"saf-osx":7,"saf-win":1},"md":{"f":{"d":0,"m":0,"t":0},"h":{"d":4, "m":0,"t":2}},"pv":{"d":0,"e":3,"i":1,"m":2}, "t":"i626g0au","vv":{"d":1,"e":1,"i":0,"m":8}}
      {"h":"2011-08-29T10:00:00+00:00","bp":{"and-and":5,"chr-osx":7,"chr-win":11,"fir-osx":3,"fir-win":17,"iex-win":1, "saf-ipa":2,"saf-iph":5,"saf-ipo":0,"saf-osx":0,"saf-win":0},"md":{"f":{"d":2,"m":1,"t":1},"h":{"d":2, "m":3,"t":0}},"pv":{"d":0,"e":1,"i":0,"m":13},"t":"i626g0au","vv":{"d":1,"e":0,"i":0,"m":1}}
      {"h":"2011-08-29T11:00:00+00:00","bp":{"and-and":5,"chr-osx":7,"chr-win":29,"fir-osx":0,"fir-win":9, "iex-win":25,"saf-ipa":3,"saf-iph":0,"saf-ipo":0,"saf-osx":1,"saf-win":1},"md":{"f":{"d":0,"m":0,"t":0},"h":{"d":4, "m":4,"t":1}},"pv":{"d":1,"e":0,"i":1,"m":11},"t":"i626g0au","vv":{"d":1,"e":2,"i":1,"m":0}}
      {"d":"2011-08-27T00:00:00+00:00","bp":{"and-and":0,"chr-osx":5,"chr-win":14,"fir-osx":1,"fir-win":19,"iex-win":26,"saf-ipa":1,"saf-iph":0,"saf-ipo":1,"saf-osx":5,"saf-win":1},"md":{"f":{"d":0,"m":0,"t":0},"h":{"d":7, "m":3,"t":0}},"pv":{"d":0,"e":2,"i":1,"m":5}, "t":"i626g0au","vv":{"d":0,"e":0,"i":0,"m":7}}
      {"d":"2011-08-28T00:00:00+00:00","bp":{"and-and":0,"chr-osx":1,"chr-win":23,"fir-osx":3,"fir-win":0, "iex-win":21,"saf-ipa":0,"saf-iph":1,"saf-ipo":0,"saf-osx":2,"saf-win":1},"md":{"f":{"d":3,"m":1,"t":0},"h":{"d":3, "m":1,"t":1}},"pv":{"d":0,"e":3,"i":0,"m":10},"t":"i626g0au","vv":{"d":0,"e":0,"i":0,"m":5}}
      {"d":"2011-08-29T00:00:00+00:00","bp":{"and-and":1,"chr-osx":2,"chr-win":25,"fir-osx":4,"fir-win":19,"iex-win":25,"saf-ipa":1,"saf-iph":0,"saf-ipo":0,"saf-osx":1,"saf-win":1},"md":{"f":{"d":1,"m":0,"t":0},"h":{"d":3, "m":3,"t":0}},"pv":{"d":0,"e":1,"i":0,"m":14},"t":"i626g0au","vv":{"d":0,"e":0,"i":1,"m":1}}
    ])
    @period = MSVStats.period
    @stats  = MSVStats.stats

  describe 'forCurrentPeriod()', ->
    it 'return last 30 days (3 here)', ->
      expect(@stats.forCurrentPeriod().length).toEqual(3)

    it 'return last 24 hours (2 here)', ->
      @period.setPeriod('24 hour')
      expect(@stats.forCurrentPeriod().length).toEqual(2)
      expect(_.first(@stats.forCurrentPeriod()).get('h')).toEqual('2011-08-29T10:00:00+00:00')

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
