class MySublimeVideo.UI.KitEditor
  constructor: ->
    this.setupInputsInitialState()
    this.setupInputsObservers()

  setupInputsInitialState: ->
    $('input[type=checkbox][data-master]').each (index, el) =>
      this.toggleDependantInputs($(el))

  setupInputsObservers: ->
    $('input[type=range]').each (index, el) =>
      $el = $(el)
      $el.on 'change', =>
        this.updateValueDisplayer($el)

    $('.expanding_handler').each (index, el) =>
      $el = $(el)
      $el.on 'click', (event) =>
        event.preventDefault()
        this.toggleExpandableBox($el)

        false

    $('input[type=checkbox][data-master]').each (index, el) =>
      $el = $(el)
      $el.on 'click', (e) =>
        this.toggleDependantInputs($el)

  updateValueDisplayer: ($el) ->
    $("##{$el.attr('id')}_value").text Math.round($el.val() * 100) / 100

  toggleExpandableBox: ($el) ->
    $el.toggleClass('expanded')
    $el.siblings('.expandable').toggle()

  toggleDependantInputs: ($el) ->
    $dependantInputs = $("input[data-dependant=#{$el.data('master')}]")

    if $el.attr('checked')?
      $dependantInputs.removeAttr 'disabled'
    else
      $dependantInputs.attr 'disabled', 'disabled'
