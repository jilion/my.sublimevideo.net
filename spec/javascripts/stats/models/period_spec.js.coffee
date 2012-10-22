describe 'MSVStats.Models.Period', ->
  beforeEach ->
    @period = new MSVStats.Models.Period()

  describe 'startTime()', ->
    it 'returns first statsDays when startIndex is null', ->
      MSVStats.statsDays = new MSVStats.Collections.Stats(daysStats)
      @period.setPeriod(type: 'days')
      expect(@period.get('startIndex')).toEqual(0)
      expect(@period.startTime()).toEqual(MSVStats.statsDays.first().time())

    it 'returns last statsDays whit index -1', ->
      MSVStats.statsDays = new MSVStats.Collections.Stats(daysStats)
      @period.setPeriod(type: 'days')
      expect(@period.startTime(-1)).toEqual(MSVStats.statsDays.last().time())

  describe 'setPeriod()', ->
    it 'sets type', ->
      @period.setPeriod(type: 'hours')
      expect(@period.get('type')).toEqual('hours')

  describe 'isSelected()', ->
    beforeEach ->
      MSVStats.statsDays = new MSVStats.Collections.Stats(daysStats)
      @period.setPeriod(type: 'days', startIndex: -10, endIndex: -1)

    it 'returns false if not good type', ->
      expect(@period.isSelected('minutes')).toEqual(false)

    it 'returns false if good type but false startIndex', ->
      expect(@period.isSelected('days', -20, -1)).toEqual(false)

    it 'returns false if good type but false endIndex', ->
      expect(@period.isSelected('days', -10, -4)).toEqual(false)

    it 'returns true if good type, startIndex & endIndex', ->
      expect(@period.isSelected('days', -10, -1)).toEqual(true)

    it 'returns true if good type, startIndex+ & endIndex+', ->
      expect(@period.isSelected('days', 29, 38)).toEqual(true)

  describe '#autosetPeriod', ->
    beforeEach ->
      MSVStats.statsSeconds = new MSVStats.Collections.StatsSeconds([{"vv":0}])
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

    it "sets '24 hours' when hours is empty but in free plan", ->
      MSVStats.sites.select('free')
      @period.autosetPeriod()
      expect(@period.get('type')).toEqual('hours')

    it "sets '30 days' when days stats are present in the count 30 days", ->
      MSVStats.statsDays = new MSVStats.Collections.StatsDays(daysStats)
      @period.autosetPeriod()
      expect(@period.get('type')).toEqual('days')
      expect(@period.get('startIndex')).toEqual(-30)
      expect(@period.get('endIndex')).toEqual(-1)

    it "sets '30 days' when days stats are only available for 30 days (or less)", ->
      MSVStats.statsDays = new MSVStats.Collections.StatsDays(emptyDaysStats)
      @period.autosetPeriod()
      expect(@period.get('type')).toEqual('days')
      expect(@period.get('startIndex')).toEqual(-30)
      expect(@period.get('endIndex')).toEqual(-1)

    it "sets 'all days' when days stats are present but not in the size of 365 days", ->
      MSVStats.statsDays = new MSVStats.Collections.StatsDays(noRecentDaysStats)
      @period.autosetPeriod()
      expect(@period.get('type')).toEqual('days')
      expect(@period.get('startIndex')).toEqual(-365)
      expect(@period.get('endIndex')).toEqual(-1)
