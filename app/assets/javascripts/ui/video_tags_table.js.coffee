class MySublimeVideo.UI.VideoTagsTable
  constructor: (@options = {}) ->
    @form   = @options.form
    @input  = @options.input
    @select = @options.select
    this.setupObservers()

  setupObservers: ->
    throttledSubmit = _.throttle(this.submit, 1000)
    @input.keypress (event) =>
      if event.which is 13 # enter keypress
        throttledSubmit()
        event.preventDefault()
    debouncedSubmit = _.debounce(this.submit, 1000)
    @input.keyup (event) => debouncedSubmit() unless event.which is 13 # enter keypress
    @select.on 'change', => this.submit()

  submit: =>
    SublimeVideo.UI.Table.showSpinner()
    params = @form.serialize()
    path = window.location.pathname
    Turbolinks.visit("#{path}?#{params}")
