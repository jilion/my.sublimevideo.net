describe 'Period', ->
  beforeEach ->
    @period = new MSVStats.Models.Period()

  describe '#setPeriod', ->
    it 'sets type and last', ->
      @period.setPeriod('24 hours')
      expect(@period.get('type')).toEqual('hours')
      expect(@period.get('last')).toEqual('24')

    it 'sets type and last (all)', ->
      @period.setPeriod('all days')
      expect(@period.get('type')).toEqual('days')
      expect(@period.get('last')).toEqual('all')

    it 'set minValue too', ->
      @period.setPeriod('24 hours', isMinValue: true)
      expect(@period.get('minValue')).toEqual('24 hours')

    it "resets custom start/end times", ->
      @period.setCustomPeriod(1000, 2000)
      @period.setPeriod('24 hours')
      expect(@period.get('startTime')).toEqual(null)
      expect(@period.get('endTime')).toEqual(null)

  describe '#setCustomPeriod', ->
    it "sets custom start/end times", ->
      @period.setCustomPeriod(1000, 2000)
      expect(@period.get('startTime')).toEqual(1000)
      expect(@period.get('endTime')).toEqual(2000)

    it "sets custom start/end times with good value order", ->
      @period.setCustomPeriod(2000, 1000)
      expect(@period.get('startTime')).toEqual(1000)
      expect(@period.get('endTime')).toEqual(2000)

    it 'clears type and last', ->
      @period.setCustomPeriod(1000, 2000)
      expect(@period.get('type')).toEqual('days')
      expect(@period.get('last')).toEqual(null)

  describe '#autosetPeriod', ->
    beforeEach ->
      @minute5  = new MSVStats.Models.Stat("mi":"#{MSVStats.Models.Period.today(s: 0).subtract(m: 5).date.getTime()}", "t":"i626g0au")
      @hour4    = new MSVStats.Models.Stat("hi":"#{MSVStats.Models.Period.today(m: 0).subtract(h: 4).date.getTime()}", "t":"i626g0au")
      @day0     = new MSVStats.Models.Stat("di":"#{MSVStats.Models.Period.today(h: 0).date.getTime()}", "t":"i626g0au")
      @day1     = new MSVStats.Models.Stat("di":"#{MSVStats.Models.Period.today(h: 0).subtract(d: 1).date.getTime()}", "t":"i626g0au")
      @day6     = new MSVStats.Models.Stat("di":"#{MSVStats.Models.Period.today(h: 0).subtract(d: 6).date.getTime()}", "t":"i626g0au")
      @day7     = new MSVStats.Models.Stat("di":"#{MSVStats.Models.Period.today(h: 0).subtract(d: 7).date.getTime()}", "t":"i626g0au")
      @day29    = new MSVStats.Models.Stat("di":"#{MSVStats.Models.Period.today(h: 0).subtract(d: 29).date.getTime()}", "t":"i626g0au")
      @day30    = new MSVStats.Models.Stat("di":"#{MSVStats.Models.Period.today(h: 0).subtract(d: 30).date.getTime()}", "t":"i626g0au")

    it "sets '60 minutes' when minutes stats are present", ->
      MSVStats.stats = new MSVStats.Collections.Stats([@minute5])
      @period.autosetPeriod()
      expect(@period.value()).toEqual('60 minutes')

    it "sets '24 hours' when hours stats are present (but no minutes stats)", ->
      MSVStats.stats = new MSVStats.Collections.Stats([@hour4])
      @period.autosetPeriod()
      expect(@period.value()).toEqual('24 hours')

    it "sets '7 days' when days stats are present in the last 7 days", ->
      MSVStats.stats = new MSVStats.Collections.Stats([@day6])
      @period.autosetPeriod()
      expect(@period.value()).toEqual('7 days')

    it "sets '30 days' when days stats are present in the last 30 days", ->
      MSVStats.stats = new MSVStats.Collections.Stats([@day7])
      @period.autosetPeriod()
      expect(@period.value()).toEqual('30 days')

    it "sets 'all days' when days stats are present but not in the last 30 days", ->
      MSVStats.stats = new MSVStats.Collections.Stats([@day30])
      @period.autosetPeriod()
      expect(@period.value()).toEqual('all days')

    it "sets 'all days' when none are present", ->
      @period.setPeriod('24 hours')
      MSVStats.stats = new MSVStats.Collections.Stats()
      @period.autosetPeriod()
      expect(@period.value()).toEqual('all days')

  describe '#value', ->
    it 'joins last and type', ->
      expect(@period.value()).toEqual('30 days')

  describe '#isCustom', ->
    it 'returns true with start/end times', ->
      @period.setCustomPeriod(1000, 2000)
      expect(@period.isCustom()).toEqual(true)

    it 'returns true with no start/end times', ->
      @period.setPeriod('24 hours')
      expect(@period.isCustom()).toEqual(false)


  describe '#periodIsAvailabe', ->
    describe "with period minValue of 60 minutes", ->
      beforeEach ->
        @period.setPeriod('60 minutes', isMinValue: true)
      it 'returns true with 60 minutes', -> expect(@period.periodIsAvailabe('60 minutes')).toBeTruthy()
      it 'returns true with 24 hours',   -> expect(@period.periodIsAvailabe('24 hours')).toBeTruthy()
      it 'returns true with 7 days',     -> expect(@period.periodIsAvailabe('7 days')).toBeTruthy()
      it 'returns true with 30 days',    -> expect(@period.periodIsAvailabe('30 days')).toBeTruthy()
      it 'returns true with all days',   -> expect(@period.periodIsAvailabe('all days')).toBeTruthy()
    describe "with period minValue of 24 hours", ->
      beforeEach ->
        @period.setPeriod('24 hours', isMinValue: true)
      it 'returns false with 60 minutes', -> expect(@period.periodIsAvailabe('60 minutes')).toBeFalsy()
      it 'returns true with 24 hours',    -> expect(@period.periodIsAvailabe('24 hours')).toBeTruthy()
      it 'returns true with 7 days',      -> expect(@period.periodIsAvailabe('7 days')).toBeTruthy()
      it 'returns true with 30 days',     -> expect(@period.periodIsAvailabe('30 days')).toBeTruthy()
      it 'returns true with all days',    -> expect(@period.periodIsAvailabe('all days')).toBeTruthy()
    describe "with period minValue of 7 days", ->
      beforeEach ->
        @period.setPeriod('7 days', isMinValue: true)
      it 'returns false with 60 minutes', -> expect(@period.periodIsAvailabe('60 minutes')).toBeFalsy()
      it 'returns false with 24 hours',   -> expect(@period.periodIsAvailabe('24 hours')).toBeFalsy()
      it 'returns true with 7 days',      -> expect(@period.periodIsAvailabe('7 days')).toBeTruthy()
      it 'returns true with 30 days',     -> expect(@period.periodIsAvailabe('30 days')).toBeTruthy()
      it 'returns true with all days',    -> expect(@period.periodIsAvailabe('all days')).toBeTruthy()
    describe "with period minValue of 30 days", ->
      beforeEach ->
        @period.setPeriod('30 days', isMinValue: true)
      it 'returns false with 60 minutes', -> expect(@period.periodIsAvailabe('60 minutes')).toBeFalsy()
      it 'returns false with 24 hours',   -> expect(@period.periodIsAvailabe('24 hours')).toBeFalsy()
      it 'returns false with 7 days',      -> expect(@period.periodIsAvailabe('7 days')).toBeFalsy()
      it 'returns true with 30 days',     -> expect(@period.periodIsAvailabe('30 days')).toBeTruthy()
      it 'returns true with all days',    -> expect(@period.periodIsAvailabe('all days')).toBeTruthy()
    describe "with period minValue of 30 days", ->
      beforeEach ->
        @period.setPeriod('all days', isMinValue: true)
      it 'returns false with 60 minutes', -> expect(@period.periodIsAvailabe('60 minutes')).toBeFalsy()
      it 'returns false with 24 hours',   -> expect(@period.periodIsAvailabe('24 hours')).toBeFalsy()
      it 'returns false with 7 days',      -> expect(@period.periodIsAvailabe('7 days')).toBeFalsy()
      it 'returns false with 30 days',     -> expect(@period.periodIsAvailabe('30 days')).toBeFalsy()
      it 'returns true with all days',    -> expect(@period.periodIsAvailabe('all days')).toBeTruthy()

  describe '.periodValueToInt', ->
    it 'returns 1060 for 60 minutes', -> expect(MSVStats.Models.Period.periodValueToInt('60 minutes')).toEqual(1060)
    it 'returns 2024 for 24 hours',   -> expect(MSVStats.Models.Period.periodValueToInt('24 hours')).toEqual(2024)
    it 'returns 3007 for 7 days',     -> expect(MSVStats.Models.Period.periodValueToInt('7 days')).toEqual(3007)
    it 'returns 3030 for 30 days',    -> expect(MSVStats.Models.Period.periodValueToInt('30 days')).toEqual(3030)
    it 'returns 4000 for all days',   -> expect(MSVStats.Models.Period.periodValueToInt('all days')).toEqual(4000)

  describe '.today', ->
    beforeEach ->
      today   = new Date()
      @year   = today.getUTCFullYear()
      @month  = today.getUTCMonth()
      @day    = today.getUTCDate()
      @hour   = today.getUTCHours()
      @minute = today.getUTCMinutes()
      @second = today.getUTCSeconds()

    it 'returns today by default (milliseconds) reseted', ->
      expect(MSVStats.Models.Period.today().date.getTime()).toEqual(Date.UTC(@year, @month, @day, @hour, @minute, @second))

    it 'returns today with seconds reseted', ->
      expect(MSVStats.Models.Period.today(s: 0).date.getTime()).toEqual(Date.UTC(@year, @month, @day, @hour, @minute))

    it 'returns today with minutes reseted', ->
      expect(MSVStats.Models.Period.today(m: 0).date.getTime()).toEqual(Date.UTC(@year, @month, @day, @hour))

    it 'returns today with hours reseted', ->
      expect(MSVStats.Models.Period.today(h: 0).date.getTime()).toEqual(Date.UTC(@year, @month, @day))

