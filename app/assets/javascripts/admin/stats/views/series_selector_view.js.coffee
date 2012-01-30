class AdminSublimeVideo.Views.SeriesSelectorView extends Backbone.View
  events:
    'click a.selector': 'updateSelected'

  updateSelected: (event) ->
    event.stopPropagation()
    clickedFilter = $(event.currentTarget)
    selection     = clickedFilter.data('value').split('.')

    this.toggleSubCategory(selection[0], _.rest(selection))
    this.toggleFilterStyle(clickedFilter)
    this.updateUrl(clickedFilter.data('value'))

    AdminSublimeVideo.stats[selection[0]].trigger('change') # redraw the chart

    false

  toggleSubCategory: (category, subCategory) ->
    if AdminSublimeVideo.stats[category].currentlySelected(subCategory)
      AdminSublimeVideo.stats[category].unselect(subCategory)
    else
      AdminSublimeVideo.stats[category].select(subCategory)

  toggleFilterStyle: (filterLink) ->
    filterLink.toggleClass 'active'

  updateUrl: (selectionString) ->
    if history and history.pushState
      currentLocation = document.location
      currentSearch = currentLocation.search
      clickedSearch = "#{encodeURIComponent(selectionString)}"

      newSearch = if currentSearch.indexOf(clickedSearch) is -1
        if currentSearch.match /^\?/
          "#{currentSearch}&#{clickedSearch}"
        else
          "?#{clickedSearch}"
      else
        currentSearch = currentSearch.replace(new RegExp("[&\?]?#{clickedSearch}"), '')
        if currentSearch.indexOf('?') is -1
          currentSearch = currentSearch.replace('&', '?')

        currentSearch

      history.pushState({}, document.title, "#{currentLocation.protocol}//#{currentLocation.hostname}#{currentLocation.pathname}#{newSearch}")
