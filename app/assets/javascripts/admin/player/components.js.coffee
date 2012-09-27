# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/

AdminSublimeVideo.UI.prepareComponentSelector = ->
  if (componentsSelectName = $('#component_select_name')).exists()
    componentsSelectName.on 'change', ->
      window.location.href = window.location.href.replace "/#{componentsSelectName.attr('data-token')}", "/#{componentsSelectName.val()}"

$(document).ready ->
  AdminSublimeVideo.UI.prepareComponentSelector()
