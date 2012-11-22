class MySublimeVideo.UI.FakeSelect
  constructor: (@handler) ->
    this.setupObservers()

  setupObservers: ->
    @handler.on 'click', =>
      $actionList = @handler.siblings('ul.actions')
      $allActionsList = $('ul.actions')

      $allActionsList.each (index, el) =>
        $(el).hide() unless $(el)[0] is $actionList[0]

      $actionList.toggle()

      $(document).one 'click', ->
        $allActionsList.hide()

      $(document).one 'keydown', ->
        Mousetrap.bind 'esc', -> $allActionsList.hide()

      false
