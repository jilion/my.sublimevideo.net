# AdminSublimeVideo.Form.Ajax handles the ajax submission of a form with the possibility
# to select the element to which attach an event listener, and also to define which event
# to listen to
#
class AdminSublimeVideo.Form.Ajax
  # Construct a new AdminSublimeVideo.Form.Ajax object.
  #
  # @param [jQuery Element] form the form element to which apply the ajax behavior
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
    @observable.on @event, (event) =>
      event.preventDefault() if @event is 'submit'
      # $('#table_spinner').show()
      params = @form.serialize()
      $.ajax @action,
        type: @method
        dataType: 'script'
        data: params
        complete: (jqXHR, textStatus) =>
          # $('#table_spinner').hide()
          if history && history.pushState?
            history.replaceState null, document.title, "#{@action}?#{params}"

      if @event is 'submit' then false else true
