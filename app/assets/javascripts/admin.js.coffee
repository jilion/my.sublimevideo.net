#= require jquery.pjax
#= require underscore
#= require highcharts/highcharts
#= require chosen-jquery
#
#= require_self
#= require_tree ./ui
#= require_tree ./admin/form
#= require_tree ./admin/app
#= require admin/stats

$.fn.exists = -> @length > 0

window.MySublimeVideo =
  UI: {}

window.AdminSublimeVideo =
  UI: {}
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

AdminSublimeVideo.documentReady = ->
  if (searchInput = $('#search_input')).exists()
    new AdminSublimeVideo.Form.Ajax(form: searchInput.parent('form'))

  ## Tags autocomplete
  if (tagList = $('.tag_list')).exists()
    form = tagList.parent('form')
    ajaxFormUpdate = (term = null, chosen = null) ->
      if term? and chosen?
        chosen.append_option
          value: term
          text: term
      $.ajax form.attr('action'),
        type: 'put'
        dataType: 'script'
        data: form.serialize()
    tagList.chosen
      create_option: ((term) -> ajaxFormUpdate(term, this))
      no_results_text: "No tags matched"
    .change (event) -> ajaxFormUpdate()

  ## Early access select
  if (earlyAccessList = $('#user_early_access')).exists()
    earlyAccessList.chosen()

  ## Filters
  if (filters = $('.filters')).exists()
    filters.find('a.remote').each (index, link) ->
      $(this).click (e) ->
        filters.find('a.remote.active').removeClass 'active'
        $(link).addClass 'active'

  ## Range form
  if (rangeInput = $('#range_input')).exists()
    new AdminSublimeVideo.Form.Ajax
      form: rangeInput.parent('form')
      observable: rangeInput
      event: 'mouseup'

    rangeInput.on 'change', (event) ->
      $('label[for=with_min_billable_video_views]').text(AdminSublimeVideo.Helpers.addCommasToInteger(rangeInput.val()))

$(document).ready ->
  AdminSublimeVideo.documentReady()
  AdminSublimeVideo.UI.prepareComponentSelector()

  $('a:not([data-remote]):not([data-behavior]):not([data-skip-pjax]):not(.selector)').pjax '[data-pjax-container]',
    timeout: 2000
  $('[data-pjax-container]')
    .on 'pjax:end', ->
      SublimeVideo.documentReady()
      AdminSublimeVideo.documentReady()

