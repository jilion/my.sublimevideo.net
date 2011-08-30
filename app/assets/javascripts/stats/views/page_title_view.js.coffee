class MSVStats.Views.PageTitleView extends Backbone.View

  initialize: () ->
    _.bindAll(this, 'render')
    this.collection.bind('change', this.render);
    this.collection.bind('reset', this.render);

  render: ->
    selectedSite   = MSVStats.sites.selectedSite()
    pageTitle      = "Stats for #{selectedSite.title()}"
    document.title = "MySublimeVideo - #{pageTitle}"
    $('h2').text(pageTitle)
    return this
