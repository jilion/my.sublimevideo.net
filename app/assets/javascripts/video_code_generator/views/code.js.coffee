class MSVVideoCodeGenerator.Views.Code extends Backbone.View
  template: JST['video_code_generator/templates/code']

  events:
    'click .get_the_code': 'render'

  #
  # BINDINGS
  #
  render: ->
    @popup = SublimeVideo.UI.Utils.openPopup
      class: 'popup'
      id: 'popup_code'
      content: this.template
        video: MSVVideoCodeGenerator.video

    false
