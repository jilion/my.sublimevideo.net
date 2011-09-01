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

  describe '#value', ->
    it 'joins last and type', ->
      expect(@period.value()).toEqual('30 days')

  describe '.todayTime', ->
    beforeEach ->
      today   = new Date()
      @year   = today.getUTCFullYear()
      @month  = today.getUTCMonth()
      @day    = today.getUTCDate()
      @hour   = today.getUTCHours()
      @minute = today.getUTCMinutes()

    it 'returns today by default (seconds) reseted', ->
      expect(MSVStats.Models.Period.today().date.getTime()).toEqual(Date.UTC(@year, @month, @day, @hour, @minute))

    it 'returns today with minutes reseted', ->
      expect(MSVStats.Models.Period.today(m: 0).date.getTime()).toEqual(Date.UTC(@year, @month, @day, @hour))

    it 'returns today with hours reseted', ->
      expect(MSVStats.Models.Period.today(h: 0).date.getTime()).toEqual(Date.UTC(@year, @month, @day))