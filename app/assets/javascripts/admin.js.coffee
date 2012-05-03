#= require underscore
#= require highcharts/highcharts

jQuery.fn.exists = -> @length > 0

window.AdminSublimeVideo =
  Models: {}
  Collections: {}
  Helpers: {}
  Routers: {}
  Views: {}

window.AdminSublimeVideo.Helpers.addCommasToInteger = (nStr) ->
  nStr += ''
  x = nStr.split('.')
  x1 = x[0]
  x2 = if x.length > 1 then '.' + x[1] else ''
  rgx = /(\d+)(\d{3})/
  while rgx.test(x1)
    x1 = x1.replace(rgx, '$1' + "'" + '$2')

  x1 + x2

jQuery(document).ready ->

  ## Live Search form
  if (searchInput = jQuery('#search_input')).exists()
    form = searchInput.parent('form')
    url  = form.attr('action')

    form.on 'submit', (event) ->
      event.preventDefault()
      jQuery('#table_spinner').show()
      params = form.serialize()
      jQuery.ajax url,
        type: form.attr('method') || 'post'
        dataType: 'script'
        data: params
        complete: (jqXHR, textStatus) ->
          jQuery('#table_spinner').hide()
          if history && history.pushState?
            history.replaceState null, document.title, "#{url}?#{params}"

      false

  ## Range form
  if (rangeInput = jQuery('#range_input')).exists()
    form = rangeInput.parent('form')
    url  = form.attr('action')

    rangeInput.on 'change', (event) ->
      jQuery('label[for=with_min_billable_video_views]').text(AdminSublimeVideo.Helpers.addCommasToInteger(rangeInput.val()))

    rangeInput.on 'mouseup', (event) ->
      jQuery('#table_spinner').show()
      params = form.serialize()
      jQuery.ajax url,
        type: form.attr('method') || 'post'
        dataType: 'script'
        data: params
        complete: (jqXHR, textStatus) ->
          jQuery('#table_spinner').hide()
          if history && history.pushState?
            history.replaceState null, document.title, "#{url}?#{params}"