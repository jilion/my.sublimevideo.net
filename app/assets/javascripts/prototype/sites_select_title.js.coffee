document.observe "dom:loaded", ->

  if sitesSelectTitle = $('sites_select_title')
    sitesSelectTitle.observe 'change', (event) ->
      currentToken = sitesSelectTitle.readAttribute('data-token')
      newToken     = sitesSelectTitle.value
      window.location.href = window.location.href.replace "/#{currentToken}/", "/#{newToken}/"
