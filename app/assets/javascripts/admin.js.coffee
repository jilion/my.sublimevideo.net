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

  ## Tags autocomplete
  if (tagInput = jQuery('.tags')).exists()
    form      = tagInput.parent('form')
    urlPrefix = if /user/.test(form.attr('action')) then 'users' else 'sites'

    tagInput.on 'keyup', (event) ->
      unless _.include([17, 37, 38, 39, 40, 91], event.which)
        word = jQuery.trim(_.last(form.find('input[type=text]').first().attr('value').split(',')))
        if /\S+/.test(word)
          jQuery('#table_spinner').show()
          jQuery.ajax "/#{urlPrefix}/autocomplete_tag_list",
            type: 'get'
            dataType: 'script'
            data: "word=#{word}"
            complete: (jqXHR, textStatus) ->
              jQuery('#table_spinner').hide()

      false

  ## Filters
  if (filters = jQuery('.filters')).exists()
    filters.find('a.remote').each (index, link) ->
      jQuery(this).click (e) ->
        filters.find('a.remote.active').removeClass 'active'
        jQuery(link).addClass 'active'

  ## Range form
  if (rangeInput = jQuery('#range_input')).exists()
    new AdminSublimeVideo.Form.Ajax
      form: rangeInput.parent('form')
      observable: rangeInput
      event: 'mouseup'

    rangeInput.on 'change', (event) ->
      jQuery('label[for=with_min_billable_video_views]').text(AdminSublimeVideo.Helpers.addCommasToInteger(rangeInput.val()))
