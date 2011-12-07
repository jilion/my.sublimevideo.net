class MSVStats.Views.StickyNoticesView extends Backbone.View
  template: JST['stats/templates/_sticky_notices']

  initialize: ->
    @options.sites.bind 'change', this.render
    @options.sites.bind 'reset', this.render

    this.render()

  render: =>
    $(@el).html(this.template(site: @options.sites.selectedSite))
    this
