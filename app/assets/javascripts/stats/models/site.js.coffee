class MSVStats.Models.Stat extends Backbone.Model
 defaults:
   t: null
   m: null
   h: null
   d: null
   pv: {}
   vv: {}
   md: {}
   bp: {}

class MSVStats.Collections.Stats extends Backbone.Collection
 model: MSVStats.Models.Stat
 url: ->
   "/sites//stats"

