class MSVVideoCodeGenerator.Helpers.UIAssetHelper

  constructor: (@scope) ->

  hide: ->
    $("##{@scope}_box").hide()

  show: ->
    $("##{@scope}_box").show()

  hideErrors: ->
    $("##{@scope}_box").removeClass 'valid'
    $("##{@scope}_src").removeClass 'errors'
    $("##{@scope}_box .inline_alert").each -> $(this).hide()

  renderValid: ->
    $("##{@scope}_box").addClass 'valid'

  renderError: (name) ->
    $("##{@scope}_#{name}").show()
    $("##{@scope}_src").addClass 'errors'

class MSVVideoCodeGenerator.Helpers.UISourceHelper extends MSVVideoCodeGenerator.Helpers.UIAssetHelper
  hideErrors: ->
    super

  renderError: (name) ->
    super name

