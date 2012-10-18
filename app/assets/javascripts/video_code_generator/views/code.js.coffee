class MSVVideoCodeGenerator.Views.Code extends Backbone.View
  template: JST['video_code_generator/templates/_code']
  videoTagTemplate: JST['video_code_generator/templates/code/_video_tag']
  iframeTagTemplate: JST['video_code_generator/templates/code/_iframe_tag']
  iframeContentTemplate: JST['video_code_generator/templates/code/_iframe_content']

  events:
    'click #get_the_code': 'render'

  initialize: ->
    @builder   = @options.builder
    @loader    = @options.loader
    @poster    = @options.poster
    @sources   = @options.sources
    @thumbnail = @options.thumbnail
    @iframe    = @options.iframe

  #
  # BINDINGS
  #
  render: ->
    @attributesHelper = new MSVVideoCodeGenerator.Helpers.AttributesHelper(@builder, MSVVideoCodeGenerator.video)
    @popup = SublimeVideo.UI.Utils.openPopup
      class: 'popup'
      id: 'popup_code'
      content: this.template
        builder: @builder
        loader: @loader
        iframe: @iframe
        video: MSVVideoCodeGenerator.video
        embedTemplate: this.embedTemplate()
        iframeTagTemplate: this.iframeTagTemplate
        videoTagTemplate: this.videoTagTemplate
        iframeContentTemplate: this.iframeContentTemplate
        attributesHelper: @attributesHelper

    false

  #
  # HELPERS
  #
  embedTemplate: ->
    if @builder.get('builderClass') is 'iframe_embed'
      this.iframeTagTemplate
    else
      this.videoTagTemplate
