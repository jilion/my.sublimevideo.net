#= require ../../models/site

class MSVStats.Models.Site extends MSV.Models.Site

  planMonthCycleVideoViews: ->
    _.reduce(MSVStats.statsDays.models, (memo, stat) ->
      if stat.time() >= this.planMonthCycleStartTime() && stat.time() <= this.planMonthCycleEndTime()
        memo + stat.get('bvv')
      else
        memo
    0, this)

class MSVStats.Collections.Sites extends MSV.Collections.Sites
  model: MSVStats.Models.Site
