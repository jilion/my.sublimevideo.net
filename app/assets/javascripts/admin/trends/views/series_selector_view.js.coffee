class AdminSublimeVideo.Views.SeriesSelectorView extends Backbone.View
  events:
    'click a.selector': 'updateSelected'

  updateSelected: (event) ->
    event.stopPropagation()
    clickedFilter = $(event.currentTarget)
    selection     = clickedFilter.data('value').split('.')

    this.toggleSubCategory(selection[0], _.rest(selection))
    this.toggleFilterStyle(clickedFilter)
    AdminSublimeVideo.trendsRouter.updateUrl(null, clickedFilter.data('value'))

    AdminSublimeVideo.graphView.render()

    false

  toggleSubCategory: (category, subCategory) ->
    if AdminSublimeVideo.trends[category].currentlySelected(subCategory)
      AdminSublimeVideo.trends[category].unselect(subCategory)
    else
      AdminSublimeVideo.trends[category].select(subCategory)

  toggleFilterStyle: (filterLink) ->
    filterLink.toggleClass 'active'
