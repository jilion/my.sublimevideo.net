class MSVStats.Views.PageTitleView extends Backbone.View

  initialize: ->
    _.bindAll this, 'render'
    @options.sites.bind 'change', this.render
    @options.sites.bind 'reset', this.render
    this.render()

  render: ->
    selectedSite   = MSVStats.sites.selectedSite()
    pageTitle      = "Stats for #{selectedSite.title()}"
    document.title = "MySublimeVideo - #{pageTitle}"
    $('h2').text(pageTitle)
    return this
