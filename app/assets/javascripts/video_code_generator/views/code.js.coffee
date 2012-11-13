class MSVVideoCodeGenerator.Views.Code extends Backbone.View
  template: JST['video_code_generator/templates/_code']
  # videoTagTemplate: JST['video_code_generator/templates/code/_video_tag']
  # iframeTagTemplate: JST['video_code_generator/templates/code/_iframe_tag']
  # iframeContentTemplate: JST['video_code_generator/templates/code/_iframe_content']

  events:
    'click #get_the_code': 'render'

  #
  # BINDINGS
  #
  render: ->
    console.log MSVVideoCodeGenerator.video
    @videoTagHelper = new MySublimeVideo.Helpers.VideoTagHelper(MSVVideoCodeGenerator.video,
      lightbox: MSVVideoCodeGenerator.video.get('displayInLightbox')
      startWithHd: MSVVideoCodeGenerator.video.get('startWithHd')
    )
    @popup = SublimeVideo.UI.Utils.openPopup
      class: 'popup'
      id: 'popup_code'
      content: this.template
        # iframe: @iframe
        video: MSVVideoCodeGenerator.video
        # embedTemplate: this.embedTemplate()
        # iframeTagTemplate: this.iframeTagTemplate
        # videoTagTemplate: this.videoTagTemplate
        # iframeContentTemplate: this.iframeContentTemplate
        videoTagHelper: @videoTagHelper

    false

  #
  # HELPERS
  #
  embedTemplate: ->
    # if @builder.get('builderClass') is 'iframe_embed'
    #   this.iframeTagTemplate
    # else
    #   this.videoTagTemplate
    this.videoTagTemplate
