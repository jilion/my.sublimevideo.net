class MSVVideoTagBuilder.Views.Preview extends Backbone.View
  template: JST['video_tag_builder/templates/_preview']

  initialize: ->
    @builder = @options.builder

  #
  # BINDINGS
  #
  render: ->
    currentScroll = $(window).scrollTop()
    $(@el).hide()

    sublimevideo.unprepare($('video').get(0)) if $('video').length

    $(@el).html this.template
      builder: @builder
      video: MSVVideoTagBuilder.video

    sublimevideo.prepare($('video').get(0)) if $('video').length

    # $(@el).data().spinner.stop()
    $(@el).show()
    $(window).scrollTop(currentScroll)

    this

  hide: ->
    $(@el).hide()
