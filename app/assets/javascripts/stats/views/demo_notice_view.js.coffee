class MSVStats.Views.DemoNoticeView extends Backbone.View
  template: JST['stats/templates/_demo_notice']

  initialize: ->
    @options.sites.bind 'change', this.render
    @options.sites.bind 'reset', this.render
    this.render()

  render: =>
    $(@el).html(this.template(statsRouter: MSVStats.statsRouter))
    this
