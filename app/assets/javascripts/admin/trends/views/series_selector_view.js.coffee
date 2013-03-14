class AdminSublimeVideo.Views.SeriesSelectorView extends Backbone.View
  events:
    'click a.selector': 'updateSelected'

  updateSelected: (event) ->
    event.stopPropagation()
    $clickedFilter = $(event.target)
    serie = $clickedFilter.attr('href').replace(/[\?#]/, '')
    selection = _.compact(serie.split('.'))

    if selection.length > 0
      this.toggleSubCategory(selection[0], _.rest(selection))
      this.toggleFilterStyle($clickedFilter)
      AdminSublimeVideo.trendsRouter.updateUrl(null, serie)

      AdminSublimeVideo.graphView.render()

    false

  toggleSubCategory: (category, subCategory) ->
    if AdminSublimeVideo.trends[category].currentlySelected(subCategory)
      AdminSublimeVideo.trends[category].unselect(subCategory)
    else
      AdminSublimeVideo.trends[category].select(subCategory)

  toggleFilterStyle: (filterLink) ->
    filterLink.toggleClass 'active'
