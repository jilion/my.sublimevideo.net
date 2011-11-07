class MSVStats.Models.Video extends Backbone.Model
  # id = video uid
  defaults:
    uo: null
    n: null
    no: null
    p: null
    cs: []
    s: {}
    vl_sum: 0 # main + extra
    vv_sum: 0 # main + extra
    vv_array: [] # main + extra
    
class MSVStats.Collections.Videos extends Backbone.Collection
  url: ->
    "/sites/#{MSVStats.sites.selectedSite.get('token')}/stats/videos.json?period=#{MSVStats.period.get('type')}"

  # Handle custom json field (total, startTime)
  parse: (data) ->
    if !data
      @total = 0
      @startTime = null
      return []
    
    @total = data.total
    @startTime = parseInt(data.start_time) * 1000 
    return data.videos

  startDate: ->
    new Date(@startTime)
