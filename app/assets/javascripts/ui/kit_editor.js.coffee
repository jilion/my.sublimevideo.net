class MySublimeVideo.UI.KitEditor
  constructor: ->
    @$lightboxTestButton = $('#lightbox-test-button')

    new MySublimeVideo.UI.DependantInputs
    this.setupModels()
    this.setupHelpers()
    this.setupInputsObservers()
    this.setupLightboxTester()

    sublimevideo.ready =>
      this.refreshVideoTagFromSettings('standard')
    #   # this.refreshVideoTagFromSettings('lightbox')

  setupModels: ->
    thumbnail = new MySublimeVideo.Models.Thumbnail(initialLink: 'text', src: 'Test')
    poster  = new MySublimeVideo.Models.Image(src: '//media.jilion.com/images/midnight_sun_800.jpg')
    sources = new MySublimeVideo.Collections.Sources([
      new MySublimeVideo.Models.Source
        src: '//media.jilion.com/videos/demo/midnight_sun_sv1_1_360p.mp4'
        embedWidth: 320
        embedHeight: 180
      new MySublimeVideo.Models.Source
        format: 'webmogg'
        src: '//media.jilion.com/videos/demo/midnight_sun_sv1_1_360p.webm'
        embedWidth: 320
        embedHeight: 180
    ])

    @video = new MySublimeVideo.Models.Video
      thumbnail: thumbnail
      poster: poster
      sources: sources

    @lightbox = new MySublimeVideo.Models.Video
      thumbnail: thumbnail
      poster: poster
      sources: sources
      displayInLightbox: true

  setupHelpers: ->
    @videoTagHelpers =
      standard: new MySublimeVideo.Helpers.VideoTagHelper(@video, forceSettings: true)
      lightbox: new MySublimeVideo.Helpers.VideoTagHelper(@lightbox, forceSettings: true)

  setupInputsObservers: ->
    $("input[type=checkbox], input[type=radio], input[type=range], input[type=text], input[type=hidden]").each (index, el) =>
      $(el).on 'change', =>
        this.refreshVideoTagFromSettings('standard')
        false

    $('input[type=range]').each (index, el) =>
      $el = $(el)
      $el.on 'change', =>
        this.updateValueDisplayer($el)

    $('input[name="kit[addons][logo][type]"]').on 'change', (e) =>
      $el = $(e.target)
      if $el.val() is 'custom'
        $('#custom_logo_fields').show()
      else
        $('#custom_logo_fields').hide()

    $('#kit_setting-logo-image_url').on 'change', (e) =>
      $el = $(e.target)

  setupLightboxTester: ->
    @$lightboxTestButton.on 'click', =>
      this.refreshVideoTagFromSettings('lightbox')

      false

  refreshVideoTagFromSettings: (type) ->
    sublimevideo.unprepare("preview-#{type}")

    switch type
      when 'standard'
        videoCode = @videoTagHelpers[type].generateVideoCode(id: 'preview-standard')
        console.log videoCode
        $('#preview-standard').replaceWith(videoCode)

      when 'lightbox'
        lightboxCode = @videoTagHelpers[type].generateLightboxCode(href: '#preview-lightbox', id: 'preview-lightbox-button', class: 'blue_button sublime')
        videoCode = @videoTagHelpers[type].generateVideoCode(id: 'preview-lightbox', class: '')

        @$lightboxTestButton.replaceWith(lightboxCode)
        $('#preview-lightbox').replaceWith(videoCode)

        @$lightboxTestButton = $('#preview-lightbox-button')

        # NEW API
        # sublimevideo.lightbox('preview-lightbox-button').open()

    sublimevideo.prepare("preview-#{type}")

  updateValueDisplayer: ($el) ->
    $("##{$el.attr('id')}_value").text Math.round($el.val() * 100) / 100
