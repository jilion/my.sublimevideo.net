class MSVStats.Views.SitesSelectView extends Backbone.View
  template: JST['stats/templates/_sites_select']

  events:
    'change select': 'updatePage'

  initialize: () ->
    _.bindAll(this, 'render')
    this.collection.bind('change', this.render);
    this.collection.bind('reset', this.render);

  render: ->
    $(this.el).html(this.template(sites: this.collection.toJSON()))
    return this

  updatePage: ->
    selectedToken = this.$('select').val()
    MSVStats.statsRouter.navigate("sites/#{selectedToken}/stats", true)