class MSVStats.Models.Site extends Backbone.Model
  defaults:
    token: null
    hostname: null
    selected: false
    plan_video_views: 0
    plan_month_cycle_start_time: null
    plan_month_cycle_end_time: null

  title: ->
    this.get('hostname') || this.get('token')

  planMonthCycleStartTime: ->
    parseInt(this.get('plan_month_cycle_start_time')) * 1000

  planMonthCycleEndTime: ->
    parseInt(this.get('plan_month_cycle_end_time')) * 1000

  planMonthCycleVideoViews: ->
    _.reduce(MSVStats.statsDays.models, (memo, stat) ->
      if stat.time() >= this.planMonthCycleStartTime() && stat.time() <= this.planMonthCycleEndTime() then memo + stat.get('vv') else memo
    0, this)

class MSVStats.Collections.Sites extends Backbone.Collection
  model: MSVStats.Models.Site
  url: '/sites'

  select: (token) ->
    MSVStats.sites.each (site) ->
      site.set(selected: (site.get('token') == token), { silent: true })
    MSVStats.sites.trigger('change')

  selectedSite: ->
    MSVStats.sites.find (site) ->
      site.get('selected')
