#= require underscore
#= require highcharts/highcharts
#
#= require_self
#= require_tree ./helpers
#= require_tree ./ui

jQuery.fn.exists = -> @length > 0

window.MySublimeVideo =
  UI: {}
  Models: {}
  Collections: {}
  Helpers: {}
  Routers: {}
  Views: {}

MySublimeVideo.UI.prepareSiteSelector = ->
  if (sitesSelectTitle = jQuery('#sites_select_title')).exists()
    sitesSelectTitle.on 'change', ->
      window.location.href = window.location.href.replace "/#{sitesSelectTitle.attr('data-token')}/", "/#{sitesSelectTitle.val()}/"

MySublimeVideo.UI.prepareEmbedCodePopups = ->
  jQuery('a.embed_code').each ->
    new MySublimeVideo.UI.EmbedCode(link: jQuery(this))

MySublimeVideo.UI.prepareFlashNotices = ->
  jQuery('#flash .notice').each ->
    new MySublimeVideo.UI.Notice(element: jQuery(this)).setupDelayedHiding()

MySublimeVideo.UI.prepareHidableNotices = ->
  jQuery('.hidable_notice').each ->
    new MySublimeVideo.UI.Notice(element: jQuery(this)).setupCloseButton()

MySublimeVideo.UI.prepareSitesStatus = ->
  if (table = jQuery('#sites_table_wrap')).exists()
    new MySublimeVideo.UI.SitesStatus(table)

MySublimeVideo.UI.preparePlansChooser = ->
  if jQuery('#plan_fields').exists()
    if jQuery('#new_site').exists()
      new MySublimeVideo.UI.NewSitePlanChooser()
    else
      new MySublimeVideo.UI.PersistedSitePlanChooser()

jQuery(document).ready ->
  MySublimeVideo.UI.prepareSiteSelector()

  MySublimeVideo.UI.prepareFlashNotices()

  MySublimeVideo.UI.prepareHidableNotices()

  MySublimeVideo.UI.prepareEmbedCodePopups()

  MySublimeVideo.UI.prepareSitesStatus()

  MySublimeVideo.UI.preparePlansChooser()

  if (moreInfoForm = jQuery('#edit_more_info')).exists()
    moreInfoForm.on 'submit', ->
      _gaq.push(['_trackEvent', 'SignUp', 'Completed', undefined, 1, true]) if _gaq?


  _.each ['new_site', 'edit_site_plan'], (formId) ->
    if (form = jQuery("##{formId}")).exists()
      form.on 'submit', (e) ->
        jQuery('#site_submit').attr('disabled', 'disabled')
