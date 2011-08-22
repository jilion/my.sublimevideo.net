class MSVStats.Views.SitesSelectView extends Backbone.View
  template: JST['stats/templates/sites_select']

  initialize: () ->
    @el = $('#sites_select')
    _.bindAll(this, 'render')

  render: ->
    @el.html(this.template(sites: this.collection.toJSON()))
    return this