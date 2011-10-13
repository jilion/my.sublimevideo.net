describe 'Site', ->
  beforeEach ->
    @site = new MSVStats.Models.Site
      plan_video_views:            200000
      plan_month_cycle_start_time: 1313625600
      plan_month_cycle_end_time:   1316044800

  describe 'planMonthCycleStartTime()', ->
    it 'returns javascript stat time', ->
      expect(@site.planMonthCycleStartTime()).toEqual(1313625600000)

  describe 'planMonthCycleEndTime()', ->
    it 'returns javascript stat time', ->
      expect(@site.planMonthCycleEndTime()).toEqual(1316044800000)

  describe 'planMonthCycleVideoViews()', ->
    beforeEach ->
      MSVStats.statsDays = new MSVStats.Collections.StatsDays(daysStats)

    it 'returns sum StatsDays video views between planMonthCycleStartTime & planMonthCycleEndTime', ->
      expect(@site.planMonthCycleVideoViews()).toEqual(244800)
