class MSVStats.Models.Stat extends Backbone.Model
  defaults:
    m: null
    pv: {}
    vv: {}
    md: {}
    bp: {}

class MSVStats.Collections.Stats extends Backbone.Collection
  model: MSVStats.Models.Stat
  url: ->
    "/sites/#{MSVStats.site_token}/stats"