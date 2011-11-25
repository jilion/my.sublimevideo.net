class MSVStats.Views.PageTitleView extends Backbone.View

  initialize: ->
    @options.sites.bind 'change', this.render
    @options.sites.bind 'reset', this.render
    this.render()

  render: =>
    if (selectedSite = MSVStats.sites.selectedSite)?
      document.title = "MySublimeVideo - Stats for #{selectedSite.title()}"
    this
