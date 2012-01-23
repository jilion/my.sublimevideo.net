class SVStats.Views.SeriesSelectorView extends Backbone.View

  events:
    'click a.selector': 'updateSelected'

  updateSelected: (event) ->
    clickedFilter = $(event.currentTarget)
    selection     = clickedFilter.data('value').split('.')

    this.toggleSubCategory(selection[0], _.rest(selection))
    this.toggleFilterStyle(clickedFilter)

    SVStats.stats[selection[0]].trigger('change') # redraw the chart

  toggleSubCategory: (category, subCategory) ->
    if SVStats.stats[category].currentlySelected(subCategory)
      SVStats.stats[category].unselect(subCategory)
    else
      SVStats.stats[category].select(subCategory)

  toggleFilterStyle: (filterLink) ->
    filterLink.toggleClass 'active'
