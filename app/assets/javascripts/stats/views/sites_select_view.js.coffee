class MSVStats.Views.SitesSelectView extends Backbone.View
  template: JST['stats/templates/_sites_select']

  events:
    'change select': 'updatePage'

  initialize: ->
    _.bindAll this, 'render' 
    @options.sites.bind 'change', this.render
    @options.sites.bind 'reset', this.render
    $('#sites_select').html(this.render().el)

  render: ->
    $(@el).html(this.template(sites: @options.sites.toJSON()))
    return this

  updatePage: ->
    currentSelectedToken = MSVStats.sites.selectedSite().get('token')
    MSVStats.pusher.unsubscribe("presence-#{currentSelectedToken}")

    newSelectedToken = this.$('select').val()
    MSVStats.statsRouter.navigate("sites/#{newSelectedToken}/stats", true)