#= require sublimevideo
#= require underscore
#= require highstock/highstock
#= require chartkick
#= require mousetrap.min
#= require chosen-jquery
#
#= require_self
#
#= require_tree ./helpers
#= require_tree ./ui
#
#= require_tree ./admin/form
#= require_tree ./admin/app
#= require admin/trends
#
#= require google-analytics-turbolinks
#= require turbolinks

window.MySublimeVideo =
  UI: {}
  Helpers: {}

window.AdminSublimeVideo =
  UI: {}
  Form: {}
  Models: {}
  Collections: {}
  Helpers: {}
  Routers: {}
  Views: {}

AdminSublimeVideo.Helpers.addCommasToInteger = (nStr) ->
  nStr += ''
  x = nStr.split('.')
  x1 = x[0]
  x2 = if x.length > 1 then '.' + x[1] else ''
  rgx = /(\d+)(\d{3})/
  while rgx.test(x1)
    x1 = x1.replace(rgx, '$1' + "'" + '$2')

  x1 + x2

AdminSublimeVideo.UI.prepareExpandableItems = ->
  $('.expanding_handler').each ->
    new MySublimeVideo.UI.ExpandableItem($(this))

AdminSublimeVideo.documentReady = ->
  AdminSublimeVideo.UI.prepareComponentSelector()
  AdminSublimeVideo.UI.prepareExpandableItems()
  MySublimeVideo.UI.TableSortLinks.setup()

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
    filters.find('a').each (index, link) ->
      $(this).click (e) ->
        SublimeVideo.UI.Table.showSpinner()
        filters.find('a.active').removeClass 'active'
        $(link).addClass 'active'

  ## Range form
  if (rangeInput = $('#range_input')).exists()
    new AdminSublimeVideo.Form.Ajax
      form: rangeInput.parent('form')
      observable: rangeInput
      event: 'mouseup'

    rangeInput.on 'change', (event) ->
      $('label[for=with_min_admin_starts]').text(AdminSublimeVideo.Helpers.addCommasToInteger(rangeInput.val()))

$(window).bind 'page:change', ->
  SublimeVideo.documentReady()
  AdminSublimeVideo.documentReady()

$(document).ready ->
  AdminSublimeVideo.documentReady()
