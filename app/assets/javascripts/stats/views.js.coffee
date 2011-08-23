class MSVStats.Views.SitesSelectView extends Backbone.View
  template: JST['stats/templates/sites_select']

  initialize: () ->
    _.bindAll(this, 'render')
    this.collection.bind('change', this.render);
    this.collection.bind('reset', this.render);

  render: ->
    $(this.el).html(this.template(sites: this.collection.toJSON()))
    return this