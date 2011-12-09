class SVStats.Models.SitesStat extends Backbone.Model
  defaults:
    fr: 0 # free
    pa: 0 # paying
    su: 0 # suspended
    ar: 0 # archived

  time: ->
    parseInt(this.id) * 1000

  date: ->
    new Date(this.time())

class SVStats.Collections.SitesStats extends Backbone.Collection
