#= require underscore
#= require highcharts/highcharts
#
#= require_self
#= require ./ui/plan_chooser
#= require_tree ./ui

window.MySublimeVideo =
  UI: {}
  Models: {}
  Collections: {}
  Helpers: {}
  Routers: {}
  Views: {}

jQuery(document).ready ->
  ## Sites select
  if (sitesSelectTitle = jQuery('#sites_select_title')).length > 0
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
  new MySublimeVideo.UI.SitesStatus() if jQuery('#sites_table_wrap')

  ## Plans chooser
  if jQuery('#plans').length > 0
    if jQuery('#new_site').length > 0
      new MySublimeVideo.UI.NewSitePlanChooser()
    else
      new MySublimeVideo.UI.PersistedSitePlanChooser()
