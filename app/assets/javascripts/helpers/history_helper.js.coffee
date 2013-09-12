class MySublimeVideo.Helpers.HistoryHelper

  @clearQueryInUrl: ->
    if history and history.pushState
      currentLocation = document.location
      history.pushState({}, document.title, "#{currentLocation.protocol}//#{currentLocation.hostname}#{currentLocation.pathname}")

  @updateQueryInUrl: (key, value) ->
    if history and history.pushState
      value = encodeURIComponent(value)
      currentLocation = document.location
      currentSearch = _.compact currentLocation.search.replace('?', '').split('&')
      newParam = if key? then "#{key}=#{value}" else value

      indexOfParams = if key?
        v = _.find(currentSearch, (param) -> param.indexOf("#{key}=") isnt -1)
        _.indexOf(currentSearch, v)
      else
        _.indexOf(currentSearch, newParam)

      if indexOfParams isnt -1
        currentSearch.splice(indexOfParams, 1)

      if key? or indexOfParams is -1
        currentSearch.push newParam

      currentSearch = currentSearch.join('&')
      if !_.isEmpty(currentSearch) then currentSearch = "?#{currentSearch}"

      history.pushState({}, document.title, "#{currentLocation.protocol}//#{currentLocation.hostname}#{currentLocation.pathname}#{currentSearch}")
