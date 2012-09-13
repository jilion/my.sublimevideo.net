# The AddAVideo handle the popup opening for the add a video popup.
#
class MySublimeVideo.UI.AddAVideo
  # Construct a new AddAVideo object.
  #
  # @option options [jQuery Element] link an a element that will trigger the add a video popup opening
  #
  constructor: (@options = {}) ->
    @popupContent = $("#js-add_a_video_popup_content")
    this.setupObserver()
    this.hashObserver()

  # Define a onClick observer for the link.
  #
  setupObserver: ->
    @options.link.on 'click', =>
      this.openPopup()
      false

  hashObserver: ->
    if window.location.hash == '#add'
      this.openPopup()

  openPopup: ->
    SublimeVideo.UI.Utils.openPopup
      class: 'popup'
      anchor: @popupContent
