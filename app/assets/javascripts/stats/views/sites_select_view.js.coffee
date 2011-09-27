class MSVStats.Views.SitesSelectView extends Backbone.View
  template: JST['stats/templates/_sites_select']

  events:
    'change select': 'updatePage'

  initialize: () ->
    _.bindAll(this, 'render')
    this.collection.bind('change', this.render);
    this.collection.bind('reset', this.render);
    $('#sites_select').html(this.render().el)

  render: ->
    $(this.el).html(this.template(sites: this.collection.toJSON()))
    return this

  updatePage: ->
    currentSelectedToken = MSVStats.sites.selectedSite().get('token')
    MSVStats.pusher.unsubscribe("private-#{currentSelectedToken}")

    newSelectedToken = this.$('select').val()
    MSVStats.statsRouter.navigate("sites/#{newSelectedToken}/stats", true)