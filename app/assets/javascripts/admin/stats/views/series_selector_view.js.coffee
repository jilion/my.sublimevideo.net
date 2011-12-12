class SVStats.Views.SeriesSelectorView extends Backbone.View

  events:
    'click a.selector': 'updateSelected'

  updateSelected: (event) ->
    value = $(event.currentTarget).data('value').split('.')
    rest = _.rest(value)
    # console.log rest
    SVStats.stats[value[0]].selected = if rest.length == 1 then rest[0] else rest

    SVStats.stats[value[0]].trigger('change')
