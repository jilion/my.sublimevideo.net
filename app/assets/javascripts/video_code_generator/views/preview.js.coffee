class MSVVideoCodeGenerator.Views.Preview extends Backbone.View
  template: JST['video_code_generator/templates/preview']

  initialize: ->
    @$kitSelector = $('#kit_id')
    @kitsSettings = JSON.parse(@$kitSelector.attr('data-settings'))

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

      sublimevideo.unprepare('video-preview') if $('#video-preview').exists()
      $(@el).html this.template
        video: MSVVideoCodeGenerator.video

      if MSVVideoCodeGenerator.video.get('displayInLightbox')
        if lightbox = sublime.lightbox('lightbox-trigger')
          lightbox.close()
          $('#video-preview').attr('data-settings', @videoTagHelpers[type].generateDataSettingsAttribute([], contentOnly: true))
          dataSettings = @videoTagHelpers[type].generateDataSettingsAttribute(['lightbox'], contentOnly: true)
          $('a#lightbox-trigger').attr('data-settings', dataSettings)
          # lightbox.open()
      else
        sublimevideo.ready =>
          sublime.prepareWithKit('video-preview', @kitsSettings[@$kitSelector.val()])

      $(@el).show()
      $(window).scrollTop(@currentScroll)

    else
      this.hide()

    this
