class MySublimeVideo.UI.VideoTagsTable
  constructor: (@options = {}) ->
    @form   = @options.form
    @input  = @options.input
    @select = @options.select
    this.setupObservers()

  setupObservers: ->
    debouncedSubmit = _.debounce(this.submit, 1000)
    @input.on "keyup", debouncedSubmit
    @select.on 'change', => this.submit()

  submit: =>
    SublimeVideo.UI.Table.showSpinner()
    params = @form.serialize()
    path = window.location.pathname
    Turbolinks.visit("#{path}?#{params}")
