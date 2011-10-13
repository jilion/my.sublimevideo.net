describe 'MSVVideoTagBuilder.Models.Image', ->
  beforeEach ->
    @image = new MSVVideoTagBuilder.Models.Image

  describe 'srcIsUrl()', ->
    it 'returns false when not an URL', ->
      @image.set(src: 'test')
      expect(@image.srcIsUrl()).toBeFalsy()

    it 'returns true when an URL', ->
      @image.set(src: 'http://test.com')
      expect(@image.srcIsUrl()).toBeTruthy()

  # describe 'planMonthCycleEndTime()', ->
  #   it 'returns javascript stat time', ->
  #     expect(@site.planMonthCycleEndTime()).toEqual(1316044800000)
  #
  # describe 'planMonthCycleVideoViews()', ->
  #   beforeEach ->
  #     MSVStats.statsDays = new MSVStats.Collections.StatsDays(daysStats)
  #
  #   it 'returns sum StatsDays video views between planMonthCycleStartTime & planMonthCycleEndTime', ->
  #     expect(@site.planMonthCycleVideoViews()).toEqual(244800)
