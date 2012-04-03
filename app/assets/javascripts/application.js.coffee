# This is a manifest file that'll be compiled into including all the files listed below.
# Add new JavaScript/Coffee code in separate files in this directory and they'll automatically
# be included in the compiled file accessible from http://example.com/assets/application.js
# It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
# the compiled file.
#
#= require global
#
#= require_self
#= require_tree ./ui

jQuery(document).ready ->
  ## Sites select
  if sitesSelectTitle = jQuery('#sites_select_title')
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

# SitesPoller make poll requests for the retrieving the up-to-dateness state of the assets of sites that don't have their assets up-to-date n the CDN
#
# var SitesPoller = Class.create({
#   initialize: function() {
#     this.pollingDelay  = 1000;
#     this.maxAttempts   = 10; // try for !1000 ms = 55 seconds
#     this.attempts      = 0;
#     this.currentSiteId = null;
#     this.poll          = null;
#     this.checkForSiteInProgress();
#   },
#   checkForSiteInProgress: function() {
#     var siteInProgress = $$('#sites span.icon.in_progress').first();
#     if (siteInProgress) {
#       this.currentSiteId = parseInt(siteInProgress.up('tr').id.replace("site_", ''), 10);
#       this.startPolling();
#     }
#   },
#   startPolling: function() {
#     if (this.poll) this.stopPolling();
#     this.poll = setTimeout(this.remoteCheckForStateUpdate.bind(this), this.pollingDelay * this.attempts);
#   },
#   stopPolling: function() {
#     clearTimeout(this.poll);
#     this.poll = null;
#   },
#   remoteCheckForStateUpdate: function() {
#     if (this.attempts < this.maxAttempts) {
#       this.attempts++;
#       new Ajax.Request('/sites/' + this.currentSiteId + '/state', { method: 'get' });
#     }
#     else {
#       this.stopPolling();
#     }
#     # this will simply reply with a HEAD OK if the state is still pending, or it'll will call the updateSite() method below if the state changed to active
#   },
#   updateSite: function(siteId) {
#     # Stop polling
#     this.stopPolling();
# 
#     # Remove "in progress" span
#     var inProgressWrap = $$("#site_" + siteId + " span.icon.in_progress").first();
#     if (inProgressWrap) inProgressWrap.remove();
#     # Show "ok" span
#     var okWrap = $$("#site_" + siteId + " td.status.box_hovering_zone div.completed").first();
#     if (okWrap) okWrap.show();
# 
#     # Check if a restart polling is needed
#     this.checkForSiteInProgress();
#   }
# });
