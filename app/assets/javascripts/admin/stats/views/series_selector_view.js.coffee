class SVStats.Views.SeriesSelectorView extends Backbone.View

  events:
    'click a.selector': 'updateSelected'

  updateSelected: (event) ->
    value = $(event.currentTarget).data('value').split('.')
    $("##{_.first(value)} a.selector").removeClass 'active'
    $(event.currentTarget).addClass 'active'

    rest = _.rest(value)
    SVStats.stats[value[0]].selected = if rest.length == 1 then rest[0] else rest

    SVStats.stats[value[0]].trigger('change')
