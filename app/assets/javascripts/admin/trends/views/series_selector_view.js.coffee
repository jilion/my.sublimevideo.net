class AdminSublimeVideo.Views.SeriesSelectorView extends Backbone.View
  events: ->
    'click a.selector': '_updateSelected'

  toggleSubCategory: (category, subCategory) ->
    if AdminSublimeVideo.trends[category].currentlySelected(subCategory)
      AdminSublimeVideo.trends[category].unselect(subCategory)
    else
      AdminSublimeVideo.trends[category].select(subCategory)

  toggleFilterStyle: (filterLink) ->
    filterLink.toggleClass 'active'

  #
  # PRIVATE
  #
  _updateSelected: (event) ->
    event.stopPropagation()
    $clickedFilter = $(event.target)
    serie = $clickedFilter.attr('href').replace(/[\?#]/, '')
    selection = _.compact(serie.split('.'))

    if selection.length > 0
      this.toggleSubCategory(selection[0], _.rest(selection))
      this.toggleFilterStyle($clickedFilter)
      MySublimeVideo.Helpers.HistoryHelper.updateQueryInUrl(null, serie)

      AdminSublimeVideo.graphView.render()

    false
