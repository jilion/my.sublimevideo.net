#= require underscore
#= require highcharts/highcharts
#
#= require_self
#= require_tree ./admin/form

jQuery.fn.exists = -> @length > 0

window.AdminSublimeVideo =
  Form: {}
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
  if (searchInput = jQuery('#search_input')).exists()
    new AdminSublimeVideo.Form.Ajax(form: searchInput.parent('form'))

  ## Range form
  if (rangeInput = jQuery('#range_input')).exists()
    new AdminSublimeVideo.Form.Ajax
      form: rangeInput.parent('form')
      observable: rangeInput
      event: 'mouseup'

    rangeInput.on 'change', (event) ->
      jQuery('label[for=with_min_billable_video_views]').text(AdminSublimeVideo.Helpers.addCommasToInteger(rangeInput.val()))
