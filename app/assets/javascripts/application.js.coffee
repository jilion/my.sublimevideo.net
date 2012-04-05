#= require underscore
#= require highcharts/highcharts
#
#= require_self
#= require ./ui/plan_chooser
#= require_tree ./ui

jQuery.fn.exists = -> @length > 0

window.MySublimeVideo =
  UI: {}
  Models: {}
  Collections: {}
  Helpers: {}
  Routers: {}
  Views: {}

jQuery(document).ready ->
  ## Sites select
  if (sitesSelectTitle = jQuery('#sites_select_title')).exists()
    sitesSelectTitle.on 'change', ->
      window.location.href = window.location.href.replace "/#{sitesSelectTitle.attr('data-token')}/", "/#{sitesSelectTitle.val()}/"

  ## Flash notices
  jQuery('#flash .notice').each ->
    new MySublimeVideo.UI.Notice(element: jQuery(this)).setupDelayedHiding()

  ## Hidable notices
  jQuery('.hidable_notice').each ->
    new MySublimeVideo.UI.Notice(element: jQuery(this)).setupCloseButton()

  ## Embed code popups
  jQuery('a.embed_code').each ->
    new MySublimeVideo.UI.EmbedCode(link: jQuery(this))

  ## Sites CDN status check
  if (table = jQuery('#sites_table_wrap')).exists()
    new MySublimeVideo.UI.SitesStatus(table)

  ## Plans chooser
  if jQuery('#plans').exists()
    if jQuery('#new_site').exists()
      new MySublimeVideo.UI.NewSitePlanChooser()
    else
      new MySublimeVideo.UI.PersistedSitePlanChooser()
