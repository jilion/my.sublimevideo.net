class MSVVideoCodeGenerator.Views.Preview extends Backbone.View
  template: JST['video_code_generator/templates/_preview']
  iframe_template: JST['video_code_generator/templates/_preview_iframe']

  initialize: ->
    @builder = @options.builder

  #
  # BINDINGS
  #
  render: ->
    currentScroll = $(window).scrollTop()
    $(@el).hide()

    sublimevideo.unprepare($('video').get(0)) if $('video').length

    $(@el).html (if @builder.get('builderClass') is 'iframe_embed' then this.iframe_template else this.template)
      builder: @builder
      posterSrc: MSVVideoCodeGenerator.video.get('poster').get('src')
      video: MSVVideoCodeGenerator.video
      sortedSources: MSVVideoCodeGenerator.video.get('sources').sortedSources(@builder.get('startWithHd'))

    sublimevideo.prepare($('video').get(0)) if $('video').length

    # $(@el).data().spinner.stop()
    $(@el).show()
    $(window).scrollTop(currentScroll)

    this

  hide: ->
    $(@el).hide()
