#= require jquery.pjax
#= require underscore
#= require highcharts/highcharts
#
#= require_self
#= require_tree ./helpers
#= require_tree ./ui
#
#= require stats
#= require video_code_generator

$.fn.exists = -> @length > 0

window.MySublimeVideo =
  UI: {}
  Models: {}
  Collections: {}
  Helpers: {}
  Routers: {}
  Views: {}

window.spinOptions =
  color:  '#d5e5ff'
  lines:  10
  length: 5
  width:  4
  radius: 8
  speed:  1
  trail:  60
  shadow: false

MySublimeVideo.UI.prepareSiteSelector = ->
  $('#sites_select_title').each ->
    new MySublimeVideo.UI.SiteSelector(select: $(this))

MySublimeVideo.UI.prepareEmbedCodePopups = ->
  $('a.player_code').each ->
    new MySublimeVideo.UI.EmbedCode(link: $(this))

MySublimeVideo.UI.prepareAddASitePopup = ->
  if (link = $('a#js-add_a_video')).exists()
    new MySublimeVideo.UI.AddAVideo(link: link)

MySublimeVideo.UI.prepareFlashNotices = ->
  $('#flash .notice').each ->
    new MySublimeVideo.UI.Notice(element: $(this)).setupDelayedHiding()

MySublimeVideo.UI.prepareHidableNotices = ->
  $('.hidable_notice').each ->
    new MySublimeVideo.UI.Notice(element: $(this)).setupCloseButton()

MySublimeVideo.UI.prepareSitesStatus = ->
  if (table = $('#sites_table_wrap')).exists()
    new MySublimeVideo.UI.SitesStatus(table)

MySublimeVideo.UI.prepareAddonsChooser = ->
  if $('#addons').exists()
    new MySublimeVideo.UI.AddonsChooser()

MySublimeVideo.UI.prepareSupportRequest = ->
  new MySublimeVideo.Helpers.SupportRequest() if $('#new_support_request').exists()

MySublimeVideo.UI.prepareFeedbackForm = ->
  new MySublimeVideo.Helpers.FeedbackForm() if $('#new_feedback').exists()

MySublimeVideo.UI.prepareVideoTagsTable = ->
  if (form = $('#js-video_tags_filter_form')).exists()
    MySublimeVideo.UI.videoTagsTable = new MySublimeVideo.UI.VideoTagsTable
      form: form
      input: $('#js-video_tags_filter_search')
      select: $('#js-video_tags_filter_select')

MySublimeVideo.documentReady = ->
  MySublimeVideo.UI.prepareSiteSelector()
  MySublimeVideo.UI.prepareFlashNotices()
  MySublimeVideo.UI.prepareHidableNotices()
  MySublimeVideo.UI.prepareEmbedCodePopups()
  MySublimeVideo.UI.prepareAddASitePopup()
  MySublimeVideo.UI.prepareSitesStatus()
  MySublimeVideo.UI.prepareAddonsChooser()
  MySublimeVideo.UI.prepareSupportRequest()
  MySublimeVideo.UI.prepareFeedbackForm()
  MySublimeVideo.UI.prepareVideoTagsTable()

  if (moreInfoForm = $('#edit_more_info')).exists()
    moreInfoForm.on 'submit', ->
      _gaq.push(['_trackEvent', 'SignUp', 'Completed', undefined, 1, true]) if _gaq?

  _.each ['new_site', 'edit_addons'], (formId) ->
    if (form = $("##{formId}")).exists()
      form.on 'submit', (e) ->
        $('#site_submit').attr('disabled', 'disabled')

$(document).ready ->
  MySublimeVideo.documentReady()

  $('a:not([data-remote]):not([data-behavior]):not([data-skip-pjax])').pjax '[data-pjax-container]'
    timeout: 1000
  $('[data-pjax-container]')
    .on 'pjax:end', ->
      # Ensure that body class is always up-to-date
      bodyClass = $('div[data-body-class]').data('body-class')
      $('body').attr("class", bodyClass)

      sublimevideo.prepare()
      SublimeVideo.documentReady()
      MySublimeVideo.documentReady()
