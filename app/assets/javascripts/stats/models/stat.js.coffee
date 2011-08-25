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

  isPeriodType: (type) ->
    switch type
      when 'minute'
        this.get('m') != null
      when 'hour'
        this.get('h') != null
      when 'day'
        this.get('d') != null

  date: ->
    dateString = this.get('m') || this.get('h') || this.get('d')
    new Date(dateString)

class MSVStats.Collections.Stats extends Backbone.Collection
  model: MSVStats.Models.Stat

  url: ->
    "/sites/#{MSVStats.sites.selectedSite().get('token')}/stats"

  bpData: ->
    this.forCurrentPeriod().reduce((memo, stat) ->
      _.each(stat.get('bp'), (hits, bp) -> memo.set(bp, hits))
      memo
    new bpData)

  forCurrentPeriod: ->
    stats = MSVStats.stats.reduce((memo, stat) ->
      memo.push(stat) if stat.isPeriodType(MSVStats.period.get('type'))
      memo
    [])
    stats = _.sortBy(stats, (stat) -> stat.date().getTime()).reverse()
    _.first(stats, MSVStats.period.get('last')).reverse()


class bpData

  set: (bp, hits) ->
    if _.isUndefined(this[bp])
      this[bp] = hits
    else
      this[bp] += hits
  