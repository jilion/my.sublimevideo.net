class SVStats.Views.SeriesSelectorView extends Backbone.View

  events:
    'click a.selector': 'updateSelected'

  updateSelected: (event) ->
    value = $(event.currentTarget).data('value').split('.')
    SVStats.statsRouter.xAxisMin = SVStats.chart.xAxis[0].getExtremes()['min']
    SVStats.statsRouter.xAxisMax = SVStats.chart.xAxis[0].getExtremes()['max']

    rest = _.rest(value)
    new_selected = if rest.length == 1 then rest[0] else rest.join('.')

    index = _.indexOf(SVStats.stats[value[0]].selected, new_selected)
    if -1 == index
      SVStats.stats[value[0]].selected.push new_selected
      $(event.currentTarget).addClass 'active'
    else
      SVStats.stats[value[0]].selected.splice(index, 1)
      $(event.currentTarget).removeClass 'active'

    SVStats.stats[value[0]].trigger('change')
