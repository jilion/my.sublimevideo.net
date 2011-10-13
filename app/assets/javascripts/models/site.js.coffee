class MSV.Models.Site extends Backbone.Model
  defaults:
    token: null
    hostname: null
    # selected: false
    plan_video_views: 0
    plan_month_cycle_start_time: null
    plan_month_cycle_end_time: null

  title: ->
    this.get('hostname') || this.get('token')

  planMonthCycleStartTime: ->
    parseInt(this.get('plan_month_cycle_start_time')) * 1000

  planMonthCycleEndTime: ->
    parseInt(this.get('plan_month_cycle_end_time')) * 1000

class MSV.Collections.Sites extends Backbone.Collection
  model: MSV.Models.Site
  url: '/sites'

  select: (token) ->
    @selectedSite = _.find this.models, (site) =>
      site.get('token') == token
    this.trigger('change')
