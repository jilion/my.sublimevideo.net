class MSVStats.Views.PeriodsSelectView extends Backbone.View
  template: JST['stats/templates/_periods_select']

  events:
    'change select': 'updatePeriod'

  initialize: () ->
    _.bindAll(this, 'render')
    this.options.period.bind('change', this.render);

  render: ->
    $(this.el).html(this.template(value: this.options.period.value()))
    return this

  updatePeriod: ->
    selectedPeriodValue = this.$('select').val()
    this.options.period.setPeriod(selectedPeriodValue)
