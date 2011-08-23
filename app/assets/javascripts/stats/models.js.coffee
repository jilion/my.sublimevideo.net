class MSVStats.Models.Site extends Backbone.Model
  defaults:
    token: null
    hostname: null
    selected: false
    
class MSVStats.Collections.Sites extends Backbone.Collection
  model: MSVStats.Models.Site
  url: '/sites'
  
  select: (token) ->
    sites.each (site) ->
      site.set(selected: (site.get('token') == token))
        
        

#class MSVStats.Models.Stat extends Backbone.Model
#  defaults:
#    t: null
#    m: null
#    h: null
#    d: null
#    pv: {}
#    vv: {}
#    md: {}
#    bp: {}
#
#class MSVStats.Collections.Stats extends Backbone.Collection
#  model: MSVStats.Models.Stat
#  url: ->
#    "/sites//stats"