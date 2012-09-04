# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/

AdminSublimeVideo.UI.prepareBundleSelector = ->
  if (bundlesSelectName = $('#bundles_select_name')).exists()
    bundlesSelectName.on 'change', ->
      window.location.href = window.location.href.replace "/#{bundlesSelectName.attr('data-token')}", "/#{bundlesSelectName.val()}"

$(document).ready ->
  AdminSublimeVideo.UI.prepareBundleSelector()
