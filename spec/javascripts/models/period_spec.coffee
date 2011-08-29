describe 'Period', ->
  beforeEach ->
    @period = new MSVStats.Models.Period()

  describe '#setPeriod', ->
    it 'sets type and last', ->
      @period.setPeriod('24 hour')
      expect(@period.get('type')).toEqual('hour')
      expect(@period.get('last')).toEqual('24')

  describe '#value', ->
    it 'joins last and type', ->
      expect(@period.value()).toEqual('30 day')