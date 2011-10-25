class MSVStats.Views.PageTitleView extends Backbone.View

  events:
    'click a#site_quick_switch_trigger': 'displaySitesList'

  initialize: ->
    _.bindAll this, 'render'
    @options.sites.bind 'change', this.render
    @options.sites.bind 'reset', this.render

    this.render()

  displaySitesList: (event) ->
    event.stopPropagation()
    $('#site_quick_switch_trigger').hide()
    $('#site_quick_switch_list').addClass('expanded')

    false

  render: ->
    selectedSite   = MSVStats.sites.selectedSite
    pageTitle      = "Stats for <a href='' data-token='#{selectedSite.get("token")}' id='site_quick_switch_trigger'>#{selectedSite.title()}</a>"
    document.title = "MySublimeVideo - Stats for #{selectedSite.title()}"
    $('h2').html(pageTitle)

    this
