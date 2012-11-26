class MSVVideoCode.Views.Code extends Backbone.View
  template: JST['video_code/templates/code']

  events:
    'click .get_the_code': 'render'

  initialize: ->
    @$kitSelector = $('#kit_id')

  #
  # BINDINGS
  #
  render: ->
    options = {}
    options['playerKit'] = @$kitSelector.val() unless @$kitSelector.val() is @$kitSelector.data('default').toString()

    @popup = SublimeVideo.UI.Utils.openPopup
      class: 'popup'
      id: 'popup_code'
      content: this.template
        video: MSVVideoCode.video
        options: options

    false
