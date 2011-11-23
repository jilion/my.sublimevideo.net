class MSV.Models.Site extends Backbone.Model
  defaults:
    token: null
    hostname: null
    plan_name: 0
    plan_video_views: 0
    plan_month_cycle_start_time: null
    plan_month_cycle_end_time: null
    stats_retention_days: null
    stats_trial_start_time: null

  title: ->
    this.get('hostname') ? "##{this.get('token')}"

  planMonthCycleStartTime: ->
    parseInt(this.get('plan_month_cycle_start_time')) * 1000

  planMonthCycleEndTime: ->
    parseInt(this.get('plan_month_cycle_end_time')) * 1000

  statsRetentionDays: ->
    this.get('stats_retention_days')

  inFreePlan: ->
    this.get('stats_retention_days') == 0

  statsTrialStartTime: ->
    parseInt(this.get('stats_trial_start_time')) * 1000

  statsTrialEndTime: (statsTrialStartTime = this.statsTrialStartTime()) ->
    date = new Date(statsTrialStartTime)
    startTimeMidnight = Date.UTC(date.getUTCFullYear(), date.getUTCMonth(), date.getUTCDate())
    startTimeMidnight + 8 * 24 * 3600 * 1000

  statsTrialIsActivable: ->
    this.inFreePlan() && this.statsTrialStartTime() == 0

class MSV.Collections.Sites extends Backbone.Collection
  model: MSV.Models.Site
  url: '/sites'

  select: (token) ->
    @selectedSite = _.find this.models, (site) =>
      site.get('token') == token
    this.trigger('change')
