class MySublimeVideo.UI.TableSortLinks
  @setup: ->
    if (tableLinks = $('table th a')).exists()
      tableLinks.click ->
        SublimeVideo.UI.Table.showSpinner()
        tableLinks.removeClass 'active'
        $(this).addClass 'active'
