class MSVVideoCodeGenerator.Views.Preview extends Backbone.View
  template: JST['video_code_generator/templates/preview']

  initialize: ->
    _.bindAll this, 'delayedRender'
    MSVVideoCodeGenerator.video.bind     'change',     this.delayedRender
    MSVVideoCodeGenerator.poster.bind    'change:src', this.delayedRender
    MSVVideoCodeGenerator.sources.bind   'change',     this.delayedRender
    MSVVideoCodeGenerator.thumbnail.bind 'change',     this.delayedRender

  # Ensure multiple sequential render are not possible
  #
  delayedRender: ->
    clearTimeout(@renderTimer) if @renderTimer
    @renderTimer = setTimeout((=> this.render()), 200)

  render: ->
    if MSVVideoCodeGenerator.video.viewable() and (!MSVVideoCodeGenerator.video.get('displayInLightbox') or MSVVideoCodeGenerator.thumbnail.viewable())
      @currentScroll = $(window).scrollTop()
      $video = $('video')

      sublimevideo.unprepare($video[0]) if $video.exists()
      $(@el).html this.template
        video: MSVVideoCodeGenerator.video

      unless MSVVideoCodeGenerator.video.get('displayInLightbox')
        $video = $('video')
        sublimevideo.ready ->
          sublimevideo.prepare($video[0]) if $video.exists()

      $(@el).show()
      $(window).scrollTop(@currentScroll)

    else
      this.hide()

    this
