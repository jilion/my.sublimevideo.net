# The EmbedCode handle the popup opening and SSL switch for the embed code popup.
#
class MySublimeVideo.UI.EmbedCode
  # Construct a new EmbedCode object.
  #
  # @option options [jQuery Element] link an a element that will trigger the embed code popup opening
  #
  constructor: (@options = {}) ->
    @token = @options.link.attr('data-token')
    @popupContent = $("#embed_code_popup_content_#{@token}")
    this.setupObservers()

  # Define a onClick observer for the link.
  #
  setupObservers: ->
    @options.link.on 'click', =>
      SublimeVideo.UI.Utils.openPopup
        class: 'popup'
        anchor: @popupContent
      this.setupTextareasSelectAll()

      false

  setupTextareasSelectAll: ->
    $("#embed_code_#{@token}, #embed_code_#{@token}_beta").on 'click', (event) =>
      textarea = $(event.delegateTarget)
      textarea.focus()
      textarea.select()
