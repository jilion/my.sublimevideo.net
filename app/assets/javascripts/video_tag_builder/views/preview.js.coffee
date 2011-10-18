class MSVVideoTagBuilder.Views.Preview extends Backbone.View
  template: JST['video_tag_builder/templates/_preview']

  #
  # BINDINGS
  #
  render: ->
    $(@el).hide()

    sublimevideo.unprepare($('video').get(0)) if $('video').length

    $(@el).html(this.template(video: MSVVideoTagBuilder.video))

    sublimevideo.prepare($('video').get(0)) if $('video').length

    # $(@el).data().spinner.stop()
    $(@el).show()

    this

  hide: ->
    $(@el).hide()
