#= require ../../models/site

class MSVStats.Models.Site extends MySublimeVideo.Models.Site

  planMonthCycleVideoViews: ->
    _.reduce(MSVStats.statsDays.models, (memo, stat) ->
      if stat.time() >= this.planMonthCycleStartTime() && stat.time() <= this.planMonthCycleEndTime()
        memo + stat.get('bvv')
      else
        memo
    0, this)

class MSVStats.Collections.Sites extends MySublimeVideo.Collections.Sites
  model: MSVStats.Models.Site
