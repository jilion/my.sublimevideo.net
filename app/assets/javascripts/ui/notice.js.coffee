# The Notice create a new (or takes an existing) notice element and can prepend it to the `#content` element
# and/or attach to it several different behaviors.
#
class MySublimeVideo.UI.Notice
  # Construct a new flash notice
  #
  # @param [Object] options the options that defines the flash message
  # @option options [jQuery Element] element the element that is a flash div (only hiding options are useful in that case)
  # @option options [String] type the type of the flash message. Can be 'notice' or 'alert'
  # @option options [String] message the actual message to display (HTML accepted)
  #
  constructor: (options) ->
    @element = options.element or jQuery('<div>', id: 'flash').html(jQuery('<div>', class: options.type).html(options.message))

  # This shows the flash notice (and remove any flash notice present before).
  #
  show: ->
    flashDiv.remove() if flashDiv = jQuery('#flash')

    jQuery('#content').prepend @element

    this.setupDelayedHiding()

  # Define a slide effect to be run on @element after a certain delay.
  #
  # @param [Object] options the options for the slide effect. Default: `{ duration: 0.7, delay: 15 }`
  # @option options [String] duration the duration in seconds of the flash hiding effect
  # @option options [String] delay the delay in seconds before the flash start being hidden
  #
  setupDelayedHiding: (options = { duration: 0.7, delay: 15 }) ->
    setTimeout((=> @element.hide('slide', { direction: 'down', duration: options.duration * 1000 })), options.delay * 1000)

  # Add a listener on the close button in the notice to close it with a fade effect
  # when close button is clicked.
  #
  # @param [Object] options the options for the fade effect. Default: `{ duration: 1.5 }`
  # @option options [String] duration the duration in seconds of the flash hiding effect
  #
  setupCloseButton: (options = { duration: 1.5 }) ->
    noticeId = @element.attr 'data-notice-id'
    console.log noticeId
    @element.find('.close').on 'click', =>
      jQuery.ajax "/notice/#{noticeId}",
        type: 'post'
        dataType: 'script'
        data: { _method: 'delete' }
        success: => @element.effect('fade', {}, options.duration * 1000, => @element.remove())

      false
