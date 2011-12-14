class MSV.Models.Site extends Backbone.Model
  defaults:
    token: null
    hostname: null
    plan_name: 0
    plan_video_views: 0
    plan_month_cycle_start_time: null
    plan_month_cycle_end_time: null
    plan_stats_retention_days: null
    trial_start_time: null

  title: ->
    if this.get('hostname')? && this.get('hostname') != '' then this.get('hostname') else "##{this.get('token')}"

  planMonthCycleStartTime: ->
    parseInt(this.get('plan_month_cycle_start_time')) * 1000

  planMonthCycleEndTime: ->
    parseInt(this.get('plan_month_cycle_end_time')) * 1000

  isInFreePlan: ->
    this.get('plan_stats_retention_days') == 0

  trialStartTime: ->
    parseInt(this.get('trial_start_time')) * 1000

  trialIsActivable: ->
    this.isInFreePlan() && this.trialStartTime() == 0

class MSV.Collections.Sites extends Backbone.Collection

  model: MSV.Models.Site
  url: '/sites'

  select: (token) ->
    @selectedSite = _.find this.models, (site) =>
      site.get('token') == token
    this.trigger('change')

  selectedSiteIsInFreePlan: ->
    if @selectedSite?
      @selectedSite.isInFreePlan()

