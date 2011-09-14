class MSVStats.Views.VVChartLegendView extends Backbone.View
  template: JST['stats/templates/_vv_chart_legend']

  initialize: () ->
    _.bindAll(this, 'render')
    this.options.stats.bind('change', this.render);
    this.options.stats.bind('reset', this.render);
    this.options.index.bind('change', this.render);

  render: ->
    $(this.el).html(this.template(index: this.options.index.get('index'), vvData: this.options.stats.vvData()))

    return this
