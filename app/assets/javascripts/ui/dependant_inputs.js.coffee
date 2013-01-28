class MySublimeVideo.UI.DependantInputs
  constructor: ->
    @masterInputs = $('input[type=checkbox][data-master]')
    this.setupInputsInitialState()
    this.setupInputsObservers()

  setupInputsInitialState: ->
    @masterInputs.each (index, el) =>
      this.toggleDependantInputsOnInit($(el))

  setupInputsObservers: ->
    @masterInputs.each (index, el) =>
      $el = $(el)
      $el.on 'click', (e) =>
        this.toggleDependantInputsOnClick($el)

  toggleDependantInputsOnInit: ($el) ->
    this.toggleDependantInputs($el)

  toggleDependantInputsOnClick: ($el) ->
    this.toggleDependantInputs($el)
    this.toggleSortableWidget($el)

  toggleDependantInputs: ($el) ->
    $dependantDiv    = $("div[data-dependant=#{$el.data('master')}]")
    $dependantInputs = $dependantDiv.find('input')

    $dependantDiv.toggleClass('disabled', !$el.prop('checked'))
    $dependantInputs.prop('disabled', !$el.prop('checked'))

  toggleSortableWidget: ($el) ->
    $('.drop_zone').sortable(if $el.prop('checked') then 'enable' else 'disable')
