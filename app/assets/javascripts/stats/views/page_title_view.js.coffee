class MSVStats.Views.PageTitleView extends Backbone.View

  initialize: ->
    @options.sites.bind 'change', this.render
    @options.sites.bind 'reset', this.render
    this.render()

  render: =>
    if MSVStats.statsRouter? && MSVStats.statsRouter.isDemo()
      document.title = "SublimeVideo - Public Stats for sublimevideo.net"
    else if (selectedSite = MSVStats.sites.selectedSite)?
      document.title = "MySublimeVideo - Stats for #{selectedSite.title()}"
    this
