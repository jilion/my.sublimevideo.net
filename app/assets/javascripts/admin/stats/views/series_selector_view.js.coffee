class AdminSublimeVideo.Views.SeriesSelectorView extends Backbone.View
  events:
    'click a.selector': 'updateSelected'

  updateSelected: (event) ->
    clickedFilter = $(event.currentTarget)
    selection     = clickedFilter.data('value').split('.')

    this.toggleSubCategory(selection[0], _.rest(selection))
    this.toggleFilterStyle(clickedFilter)

    AdminSublimeVideo.stats[selection[0]].trigger('change') # redraw the chart

  toggleSubCategory: (category, subCategory) ->
    if AdminSublimeVideo.stats[category].currentlySelected(subCategory)
      AdminSublimeVideo.stats[category].unselect(subCategory)
    else
      AdminSublimeVideo.stats[category].select(subCategory)

  toggleFilterStyle: (filterLink) ->
    filterLink.toggleClass 'active'
