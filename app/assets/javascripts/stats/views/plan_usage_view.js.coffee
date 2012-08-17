class MSVStats.Views.PlanUsageView extends Backbone.View
  template: JST['stats/templates/_plan_usage']

  initialize: ->
    @options.statsDays.bind 'init', this.render
    @options.statsDays.bind 'reset', this.render

  render: =>
    @site = MSVStats.site
    @plan =
      name:                 @site.get('plan_name')
      videoViews:           @site.get('plan_video_views')
      monthCycleVideoViews: @site.planMonthCycleVideoViews()
      monthCycleStartTime:  @site.planMonthCycleStartTime()
      monthCycleEndTime:    @site.planMonthCycleEndTime()
    $(@el).html(this.template(site: @site, plan: @plan, stats: @options.statsDays))
    return this

