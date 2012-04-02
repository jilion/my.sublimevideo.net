# The Flash create a new flash notice element and prepend it to the `#content` element.
#
class MySublimeVideo.UI.Flash
  # Construct a new flash notice
  #
  # @param [Object] options the options that defines the flash message
  # @option options [jQuery Element] element the element that is a flash div (only hiding options are useful in that case)
  # @option options [String] type the type of the flash message. Can be 'notice' or 'alert'
  # @option options [String] message the actual message to display (HTML accepted)
  # @option options [String] delay the delay in seconds before the flash start being hidden (default: 15)
  # @option options [String] duration the duration in seconds of the flash hiding effect (default: 0.7)
  #
  constructor: (@options = { type: 'notice', delay: 15, duration: 0.7 }) ->
    @element = @options.element or jQuery('<div>', id: 'flash').html(jQuery('<div>', class: @options.type).html(@options.message))

  # This shows the flash notice (and remove any flash notice present before).
  #
  show: ->
    flashDiv.remove() if flashDiv = jQuery('#flash')

    jQuery('#content').prepend @element

    this.setupDelayedHiding()

  # @private
  #
  setupDelayedHiding: ->
    # TODO: FIX THIS!!!!!!! NO TRANSITION AT THE MOMENT
    # setTimeout((-> @element.hide('top:40px', duration: @options.duration)), @options.delay * 1000)
    # setTimeout((=> @element.hide('slide', {}, @options.duration)), @options.delay * 1000)
    setTimeout((=> @element.toggleClass('hidden', @options.duration * 1000)), @options.delay * 1000)
