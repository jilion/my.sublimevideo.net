class MSVVideoCode.Views.Preview extends Backbone.View
  template: JST['video_code/templates/preview']

  initialize: ->
    @$kitSelector = $('#kit_id')
    @kitsSettings = @$kitSelector.data('settings')

    _.bindAll this, 'delayedRender'
    MSVVideoCode.video.bind     'change',     this.delayedRender
    MSVVideoCode.poster.bind    'change:src', this.delayedRender
    MSVVideoCode.sources.bind   'change',     this.delayedRender
    MSVVideoCode.thumbnail.bind 'change',     this.delayedRender

  # Ensure multiple sequential render are not possible
  #
  delayedRender: ->
    clearTimeout(@renderTimer) if @renderTimer
    @renderTimer = setTimeout((=> this.render()), 200)

  render: ->
    if MSVVideoCode.video.viewable() and (!MSVVideoCode.video.get('displayInLightbox') or MSVVideoCode.thumbnail.viewable())
      @currentScroll = $(window).scrollTop()

      sublime.unprepare('video-preview') if $('#video-preview').exists()

      $(@el).html this.template
        video: MSVVideoCode.video
        options: options

      if MSVVideoCode.video.get('displayInLightbox')
        sublime.prepare('lightbox-trigger')
      else
        sublime.prepareWithKit('video-preview', @kitsSettings[@$kitSelector.val()])

      $(window).scrollTop(@currentScroll)
      $(@el).show()

      if $('#video_code_form').attr('data-assistant') is 'true'
        options = {}
        options['playerKit'] = @$kitSelector.val() unless @$kitSelector.val() is @$kitSelector.attr('data-default')
        if MSVVideoCode.video.get('displayInLightbox')
          $('#lightbox_code_for_textarea').val(new MySublimeVideo.Helpers.VideoTagHelper(MSVVideoCode.video).generateLightboxCode(href: 'video1'))
          options['id'] = 'video1'
        else
          $('#lightbox_code_for_textarea').val('')
        $('#video_code_for_textarea').val(new MySublimeVideo.Helpers.VideoTagHelper(MSVVideoCode.video).generateVideoCode(options))

    else
      $(@el).hide()

    this
