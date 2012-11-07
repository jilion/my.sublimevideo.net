# The LoaderCode handle the popup for the loader code popup.
#
class MySublimeVideo.UI.LoaderCode
  # Construct a new LoaderCode object.
  #
  # @option options [jQuery Element] link an a element that will trigger the loader code popup opening
  #
  constructor: (@options = {}) ->
    @token = @options.link.attr('data-token')
    @popupContent = $("#loader_code_popup_content_#{@token}")
    this.setupObservers()

  # Define a onClick observer for the link.
  #
  setupObservers: ->
    @options.link.on 'click', =>
      SublimeVideo.UI.Utils.openPopup
        class: 'popup'
        anchor: @popupContent

      false
