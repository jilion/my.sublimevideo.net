class MySublimeVideo.UI.KitsPage
  constructor: ->
    sublime.ready =>
      this.refreshVideoTagFromSettings()

  refreshVideoTagFromSettings: (type) ->
    $('li.kit').each (index, el) =>
      $li = $(el)
      liId = $li.attr('id')

      sublime.prepareWithKit("preview_#{liId}", $li.data('settings'))

