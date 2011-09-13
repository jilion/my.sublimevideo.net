class MSVStats.Views.UpdateDateView extends Backbone.View
  template: JST['stats/templates/_update_date']

  initialize: () ->
    _.bindAll(this, 'render')
    this.collection.bind('change', this.render);
    this.collection.bind('reset', this.render);

  render: ->
    updateDate = this.collection.lastStatsDate()
    $(this.el).html(this.template(updateDate: updateDate))
    return this