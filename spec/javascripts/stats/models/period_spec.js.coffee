describe 'Period', ->
  beforeEach ->
    @period = new MSVStats.Models.Period()

  describe 'setPeriod()', ->
    it 'sets type', ->
      @period.setPeriod(type: 'hours')
      expect(@period.get('type')).toEqual('hours')

    it "resets custom start/end times", ->
      @period.setCustomPeriod(1000, 2000)
      @period.setPeriod(type: 'hours')
      expect(@period.get('startTime')).toEqual(null)
      expect(@period.get('endTime')).toEqual(null)

  describe 'setCustomPeriod()', ->
    it "sets custom start/end times", ->
      @period.setCustomPeriod(1000, 2000)
      expect(@period.get('startTime')).toEqual(1000)
      expect(@period.get('endTime')).toEqual(2000)

    it "sets custom start/end times with good value order", ->
      @period.setCustomPeriod(2000, 1000)
      expect(@period.get('startTime')).toEqual(1000)
      expect(@period.get('endTime')).toEqual(2000)

    it 'clears type and count', ->
      @period.setCustomPeriod(1000, 2000)
      expect(@period.get('type')).toEqual('days')

  describe '#autosetPeriod', ->
    beforeEach ->
      MSVStats.statsMinutes = new MSVStats.Collections.StatsMinutes([{"vv":0}])
      MSVStats.statsHours   = new MSVStats.Collections.StatsHours([{"vv":0}])
      MSVStats.statsDays    = new MSVStats.Collections.StatsDays([{"vv":0}])

    it "sets '60 minutes' when minutes stats are present", ->
      MSVStats.statsMinutes.reset([{"vv":1}])
      @period.autosetPeriod()
      expect(@period.get('type')).toEqual('minutes')

    it "sets '24 hours' when hours stats are present (but no minutes stats)", ->
      MSVStats.statsHours.reset([{"vv":1}])
      @period.autosetPeriod()
      expect(@period.get('type')).toEqual('hours')

    it "sets '30 days' when days stats are present in the count 30 days", ->
      MSVStats.statsDays = new MSVStats.Collections.Stats(daysStats)
      @period.autosetPeriod()
      expect(@period.get('type')).toEqual('days')
      expect(@period.get('startTime')).toEqual(MSVStats.statsDays.at(MSVStats.statsDays.length - 30).time())
      expect(@period.get('endTime')).toEqual(MSVStats.statsDays.last().time())

    #
    # it "sets 'all days' when days stats are present but not in the count 30 days", ->
    #   MSVStats.stats = new MSVStats.Collections.Stats([@day30])
    #   @period.autosetPeriod()
    #   expect(@period.value()).toEqual('all days')

    it "sets 'all days' when none are present", ->
      @period.autosetPeriod()
      expect(@period.get('type')).toEqual('days')
      expect(@period.get('startTime')).toEqual(null)
      expect(@period.get('endTime')).toEqual(null)

  describe 'isCustom()', ->
    it 'returns true with start/end times', ->
      @period.setCustomPeriod(1000, 2000)
      expect(@period.isCustom()).toEqual(true)

    it 'returns true with no start/end times', ->
      @period.setPeriod(type: 'hours')
      expect(@period.isCustom()).toEqual(false)

  describe 'isClear()', ->
    it 'returns true when all attributes are null', ->
      expect(@period.isClear()).toEqual(true)

    it 'returns true when at least one attribute is present', ->
      @period.setPeriod(type: 'hours')
      expect(@period.isClear()).toEqual(false)


  # describe '#periodIsAvailabe', ->
  #   describe "with period minValue of 60 minutes", ->
  #     beforeEach ->
  #       @period.setPeriod('60 minutes', isMinValue: true)
  #     it 'returns true with 60 minutes', -> expect(@period.periodIsAvailabe('60 minutes')).toBeTruthy()
  #     it 'returns true with 24 hours',   -> expect(@period.periodIsAvailabe('24 hours')).toBeTruthy()
  #     it 'returns true with 7 days',     -> expect(@period.periodIsAvailabe('7 days')).toBeTruthy()
  #     it 'returns true with 30 days',    -> expect(@period.periodIsAvailabe('30 days')).toBeTruthy()
  #     it 'returns true with all days',   -> expect(@period.periodIsAvailabe('all days')).toBeTruthy()
  #   describe "with period minValue of 24 hours", ->
  #     beforeEach ->
  #       @period.setPeriod('24 hours', isMinValue: true)
  #     it 'returns false with 60 minutes', -> expect(@period.periodIsAvailabe('60 minutes')).toBeFalsy()
  #     it 'returns true with 24 hours',    -> expect(@period.periodIsAvailabe('24 hours')).toBeTruthy()
  #     it 'returns true with 7 days',      -> expect(@period.periodIsAvailabe('7 days')).toBeTruthy()
  #     it 'returns true with 30 days',     -> expect(@period.periodIsAvailabe('30 days')).toBeTruthy()
  #     it 'returns true with all days',    -> expect(@period.periodIsAvailabe('all days')).toBeTruthy()
  #   describe "with period minValue of 7 days", ->
  #     beforeEach ->
  #       @period.setPeriod('7 days', isMinValue: true)
  #     it 'returns false with 60 minutes', -> expect(@period.periodIsAvailabe('60 minutes')).toBeFalsy()
  #     it 'returns false with 24 hours',   -> expect(@period.periodIsAvailabe('24 hours')).toBeFalsy()
  #     it 'returns true with 7 days',      -> expect(@period.periodIsAvailabe('7 days')).toBeTruthy()
  #     it 'returns true with 30 days',     -> expect(@period.periodIsAvailabe('30 days')).toBeTruthy()
  #     it 'returns true with all days',    -> expect(@period.periodIsAvailabe('all days')).toBeTruthy()
  #   describe "with period minValue of 30 days", ->
  #     beforeEach ->
  #       @period.setPeriod('30 days', isMinValue: true)
  #     it 'returns false with 60 minutes', -> expect(@period.periodIsAvailabe('60 minutes')).toBeFalsy()
  #     it 'returns false with 24 hours',   -> expect(@period.periodIsAvailabe('24 hours')).toBeFalsy()
  #     it 'returns false with 7 days',      -> expect(@period.periodIsAvailabe('7 days')).toBeFalsy()
  #     it 'returns true with 30 days',     -> expect(@period.periodIsAvailabe('30 days')).toBeTruthy()
  #     it 'returns true with all days',    -> expect(@period.periodIsAvailabe('all days')).toBeTruthy()
  #   describe "with period minValue of 30 days", ->
  #     beforeEach ->
  #       @period.setPeriod('all days', isMinValue: true)
  #     it 'returns false with 60 minutes', -> expect(@period.periodIsAvailabe('60 minutes')).toBeFalsy()
  #     it 'returns false with 24 hours',   -> expect(@period.periodIsAvailabe('24 hours')).toBeFalsy()
  #     it 'returns false with 7 days',      -> expect(@period.periodIsAvailabe('7 days')).toBeFalsy()
  #     it 'returns false with 30 days',     -> expect(@period.periodIsAvailabe('30 days')).toBeFalsy()
  #     it 'returns true with all days',    -> expect(@period.periodIsAvailabe('all days')).toBeTruthy()
  #
  # describe '.periodValueToInt', ->
  #   it 'returns 1060 for 60 minutes', -> expect(MSVStats.Models.Period.periodValueToInt('60 minutes')).toEqual(1060)
  #   it 'returns 2024 for 24 hours',   -> expect(MSVStats.Models.Period.periodValueToInt('24 hours')).toEqual(2024)
  #   it 'returns 3007 for 7 days',     -> expect(MSVStats.Models.Period.periodValueToInt('7 days')).toEqual(3007)
  #   it 'returns 3030 for 30 days',    -> expect(MSVStats.Models.Period.periodValueToInt('30 days')).toEqual(3030)
  #   it 'returns 4000 for all days',   -> expect(MSVStats.Models.Period.periodValueToInt('all days')).toEqual(4000)

  # describe '.today', ->
  #   beforeEach ->
  #     today   = new Date()
  #     @year   = today.getUTCFullYear()
  #     @month  = today.getUTCMonth()
  #     @day    = today.getUTCDate()
  #     @hour   = today.getUTCHours()
  #     @minute = today.getUTCMinutes()
  #     @second = today.getUTCSeconds()
  #
  #   it 'returns today by default (milliseconds) reseted', ->
  #     expect(MSVStats.Models.Period.today().date.getTime()).toEqual(Date.UTC(@year, @month, @day, @hour, @minute, @second))
  #
  #   it 'returns today with seconds reseted', ->
  #     expect(MSVStats.Models.Period.today(s: 0).date.getTime()).toEqual(Date.UTC(@year, @month, @day, @hour, @minute))
  #
  #   it 'returns today with minutes reseted', ->
  #     expect(MSVStats.Models.Period.today(m: 0).date.getTime()).toEqual(Date.UTC(@year, @month, @day, @hour))
  #
  #   it 'returns today with hours reseted', ->
  #     expect(MSVStats.Models.Period.today(h: 0).date.getTime()).toEqual(Date.UTC(@year, @month, @day))

