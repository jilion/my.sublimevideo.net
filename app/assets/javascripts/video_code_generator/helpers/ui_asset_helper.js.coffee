class MSVVideoCodeGenerator.Helpers.UIAssetHelper

  constructor: (@scope) ->

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
    # $(".source_error").each -> $(this).hide()
    # $(".source_warning").each -> $(this).hide()

  renderError: (name) ->
    super name
    # if $(".#{name}") then $(".#{name}").show()

