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