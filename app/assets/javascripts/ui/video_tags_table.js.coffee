class MySublimeVideo.UI.VideoTagsTable

  constructor: (@options = {}) ->
    @form   = @options.form
    @input  = @options.input
    @select = @options.select
    this.setupObservers()

  setupObservers: ->
    throttledSubmit = _.throttle(this.submit, 1000)
    @input.on "keyup", throttledSubmit
    @select.on 'change', => this.submit()

  submit: =>
    SublimeVideo.UI.Table.showSpinner()
    @form.submit()
    if history and history.pushState?
      history.pushState({ isHistory: true }, document.title, "#{@form.attr('action')}?#{@form.serialize()}")

  updateSortParams: (sortParam, value) ->
    sortParamClass = 'js-video_tags_sort_param'
    @form.find(".#{sortParamClass}").remove()
    $('<input>').attr(
      type: 'hidden'
      name: sortParam
      value: value
      class: sortParamClass
    ).appendTo(@form)
