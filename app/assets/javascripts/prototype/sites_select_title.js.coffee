document.observe "dom:loaded", ->
  
  if sitesSelectTitle = $('sites_select_title')
    sitesSelectTitle.observe 'change', ->
      currentToken = sitesSelectTitle.readAttribute('data-token')
      newToken     = event.target.value
      window.location.href = window.location.href.replace "/#{currentToken}/", "/#{newToken}/"
