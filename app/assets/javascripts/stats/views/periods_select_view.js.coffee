class MSVStats.Views.PeriodsSelectView extends Backbone.View
  template: JST['stats/templates/_periods_select']

  events:
    'change select': 'updatePeriod'

  initialize: () ->
    _.bindAll(this, 'render')
    this.options.period.bind('change', this.render);
    this.collection.bind('change', this.render);
    this.collection.bind('reset', this.render);

  render: ->
    $(this.el).html(this.template(period: this.options.period))
    return this

  updatePeriod: ->
    selectedPeriodValue = this.$('select').val()
    this.options.period.setPeriod(selectedPeriodValue)
