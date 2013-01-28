#= require sublimevideo
#= require jquery.pjax
#= require underscore
#= require highcharts/highcharts
#= require mousetrap.min
#= require backbone
#
#= require_self
#= require_tree ./helpers
#= require_tree ./models
#= require_tree ./templates
#= require_tree ./ui
#
#= require stats
#= require video_code

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

MySublimeVideo.UI.prepareFakeSelectors = ->
  $('a.show_button, a.site_select').each ->
    new MySublimeVideo.UI.FakeSelect($(this))

MySublimeVideo.UI.prepareLoaderCodePopups = ->
  $('a.loader_code').each ->
    new MySublimeVideo.UI.LoaderCode(link: $(this))

MySublimeVideo.UI.prepareAddASitePopup = ->
  if ($link = $('a#js-add_a_video')).exists()
    new MySublimeVideo.UI.AddAVideo(link: $link)

MySublimeVideo.UI.prepareFlashNotices = ->
  $('#flash .notice').each ->
    new MySublimeVideo.UI.Notice(element: $(this)).setupDelayedHiding()

MySublimeVideo.UI.prepareHidableNotices = ->
  $('.hidable_notice').each ->
    new MySublimeVideo.UI.Notice(element: $(this)).setupCloseButton()

MySublimeVideo.UI.prepareSitesStatus = ->
  if ($table = $('#sites_table_wrap')).exists()
    new MySublimeVideo.UI.SitesStatus($table)

MySublimeVideo.UI.prepareAddonsChooser = ->
  if ($form = $('#edit_addons')).exists()
    new MySublimeVideo.UI.AddonsChooser($form)

MySublimeVideo.UI.prepareGrandFatherPlanPopUp = ->
  if ($textDiv = $('#grandfather_plan')).exists()
    new MySublimeVideo.UI.GrandFatherPlanPopUp($textDiv)

MySublimeVideo.UI.prepareExpandableItems = ->
  $('.expanding_handler').each ->
    new MySublimeVideo.UI.ExpandableItem($(this))

MySublimeVideo.UI.prepareKitsPage = ->
  if $('#kits').exists()
    new MySublimeVideo.UI.KitsPage

MySublimeVideo.UI.prepareKitEditor = ->
  $('form.kit_editor').each ->
    new MySublimeVideo.UI.KitEditor

MySublimeVideo.UI.prepareSupportRequest = ->
  new MySublimeVideo.Helpers.SupportRequest() if $('#new_support_request').exists()

MySublimeVideo.UI.prepareFeedbackForm = ->
  new MySublimeVideo.Helpers.FeedbackForm() if $('#new_feedback').exists()

MySublimeVideo.UI.prepareVideoTagsTable = ->
  if ($form = $('#js-video_tags_filter_form')).exists()
    MySublimeVideo.UI.videoTagsTable = new MySublimeVideo.UI.VideoTagsTable
      form: $form
      input: $('#js-video_tags_filter_search')
      select: $('#js-video_tags_filter_select')

MySublimeVideo.documentReady = ->
  MySublimeVideo.UI.prepareFakeSelectors()
  MySublimeVideo.UI.prepareFlashNotices()
  MySublimeVideo.UI.prepareHidableNotices()
  MySublimeVideo.UI.prepareLoaderCodePopups()
  MySublimeVideo.UI.prepareAddASitePopup()
  MySublimeVideo.UI.prepareSitesStatus()
  MySublimeVideo.UI.prepareAddonsChooser()
  MySublimeVideo.UI.prepareGrandFatherPlanPopUp()
  MySublimeVideo.UI.prepareExpandableItems()
  MySublimeVideo.UI.prepareKitsPage()
  MySublimeVideo.UI.prepareKitEditor()
  MySublimeVideo.UI.prepareSupportRequest()
  MySublimeVideo.UI.prepareFeedbackForm()
  MySublimeVideo.UI.prepareVideoTagsTable()

  if (moreInfoForm = $('#edit_more_info')).exists()
    moreInfoForm.on 'submit', ->
      _gaq.push(['_trackEvent', 'SignUp', 'Completed', undefined, 1, true]) if _gaq?

  $('form.disableable').on 'submit', (event) ->
    $('button[type=submit]').attr('disabled', 'disabled')

MySublimeVideo.prepareVideosAndLightboxes = ->
  sublime.ready ->
    $(".sublime").each (index, el) ->
      sublime.prepare el
  sublime.load()

$(document).ready ->
  MySublimeVideo.documentReady()

  $('a:not([data-remote]):not([data-behavior]):not([data-skip-pjax])').pjax '[data-pjax-container]'
    timeout: 1000
  $('[data-pjax-container]').on 'pjax:end', ->
    # Ensure that body class is always up-to-date
    bodyClass = $('div[data-body-class]').data('body-class')
    $('body').attr("class", bodyClass)

    SublimeVideo.documentReady()
    MySublimeVideo.documentReady()
    MySublimeVideo.prepareVideosAndLightboxes()
    SublimeVideo.UI.updateActiveItemMenus()
