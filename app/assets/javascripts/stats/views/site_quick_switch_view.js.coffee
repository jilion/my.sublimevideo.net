class MSVStats.Views.SiteQuickSwitchView extends Backbone.View
  template: JST['templates/_site_quick_switch']

  events:
    'click ul#site_quick_switch_list li a': 'updatePage'

  initialize: ->
    _.bindAll this, 'render'
    @options.sites.bind 'change', this.render
    @options.sites.bind 'reset', this.render

    this.render()

  render: ->
    $(@el).html(this.template(sites: @options.sites))

    this

  updatePage: (event) ->
    event.stopPropagation()
    currentSelectedToken = MSVStats.sites.selectedSite.get('token')
    newSelectedToken = $(event.target).data('token')

    # Change the active link in the sites' list
    # @sitesList.find('.active')[0].removeClass('active')
    # event.target.addClass('active')

    this.hideSitesList()

    if newSelectedToken isnt currentSelectedToken
      $('#site_quick_switch_trigger').text $(event.target).text()
      MSVStats.pusher.unsubscribe("presence-#{currentSelectedToken}")
      MSVStats.statsRouter.navigate("sites/#{newSelectedToken}/stats", true)

    false

  hideSitesList: (event) ->
    if event then event.stopPropagation()
    $('#site_quick_switch_list').removeClass('expanded')
    $('#site_quick_switch_trigger').show()
