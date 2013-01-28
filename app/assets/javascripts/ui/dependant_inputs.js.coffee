class MySublimeVideo.UI.DependantInputs
  constructor: ->
    @$lightboxTestButton = $('#lightbox-test-button')

    this.setupInputsInitialState()
    this.setupInputsObservers()

  setupInputsInitialState: ->
    $('input[type=checkbox][data-master]').each (index, el) =>
      this.toggleDependantInputs($(el))

  setupInputsObservers: ->
    $('input[type=checkbox][data-master]').each (index, el) =>
      $el = $(el)
      $el.on 'click', (e) =>
        this.toggleDependantInputs($el)

  toggleDependantInputs: ($el) ->
    $dependantInputs = $("input[data-dependant=#{$el.data('master')}]")

    if $el.prop('checked')
      $dependantInputs.removeAttr 'disabled'
    else
      $dependantInputs.attr 'disabled', 'disabled'
