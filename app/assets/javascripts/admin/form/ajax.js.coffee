# The EmbedCode handle the popup opening and SSL switch for the embed code popup.
#
class AdminSublimeVideo.Form.Ajax
  # Construct a new Ajax object.
  #
  # @param [jQuery Element] form the form element to which apply the Ajax behavior
  # @param [Object] options the options that defines the ajax object
  # @option options [jQuery Element] form the form element
  # @option options [jQuery Element] observable the element to observe (default to form)
  # @option options [String] event the event to observe (default to 'submit')
  # @option options [String] action the action to request (default to form's action)
  # @option options [String] method the method to request (default to form's method)
  #
  constructor: (@options = {}) ->
    @form       = @options.form
    @observable = @options.observable or @form
    @event      = @options.event or 'submit'
    @action     = @options.action or @form.attr('action')
    @method     = @options.method or @form.attr('method') or 'post'
    this.setupObservers()

  # Define a onSubmit observer for the form.
  #
  setupObservers: ->
    console.log @form
    @observable.on @event, (event) =>
      event.preventDefault() if @event is 'submit'
      # jQuery('#table_spinner').show()
      params = @form.serialize()
      console.log params
      jQuery.ajax @action,
        type: @method
        dataType: 'script'
        data: params
        complete: (jqXHR, textStatus) =>
          # jQuery('#table_spinner').hide()
          if history && history.pushState?
            history.replaceState null, document.title, "#{@action}?#{params}"

      if @event is 'submit' then false else true
