class MySublimeVideo.UI.KitEditor
  constructor: ->
    @$lightboxTestButton = $('#lightbox-test-button')

    this.setupInputsInitialState()
    this.setupModels()
    this.setupHelpers()
    this.setupInputsObservers()
    # this.setupPreviewRefresher()
    this.setupLightboxTester()

    sublimevideo.ready =>
      this.refreshVideoTagFromSettings('standard')
    #   # this.refreshVideoTagFromSettings('lightbox')

  setupInputsInitialState: ->
    $('input[type=checkbox][data-master]').each (index, el) =>
      this.toggleDependantInputs($(el))

  setupModels: ->
    thumbnail = new MySublimeVideo.Models.Thumbnail(initialLink: 'text', src: 'Test')
    poster  = new MySublimeVideo.Models.Image(src: '//media.jilion.com/images/midnight_sun_800.jpg')
    sources = new MySublimeVideo.Collections.Sources([
      new MySublimeVideo.Models.Source().setAndPreloadSrc('//media.jilion.com/videos/demo/midnight_sun_sv1_1_360p.mp4')
      new MySublimeVideo.Models.Source(format: 'webmogg').setAndPreloadSrc('//media.jilion.com/videos/demo/midnight_sun_sv1_1_360p.webm')
    ])

    @video = new MySublimeVideo.Models.Video
      thumbnail: thumbnail
      poster: poster
      sources: sources

  setupHelpers: ->
    @videoTagHelpers =
      standard: new MySublimeVideo.Helpers.VideoTagHelper(@video, type: 'standard', forceSettings: true)
      lightbox: new MySublimeVideo.Helpers.VideoTagHelper(@video, type: 'lightbox', forceSettings: true)

  setupInputsObservers: ->
    $("input[type=checkbox], input[type=radio], input[type=range], input[type=text]").each (index, el) =>
      $(el).on 'change', =>
        this.refreshVideoTagFromSettings('standard')
        false

    $('input[type=range]').each (index, el) =>
      $el = $(el)
      $el.on 'change', =>
        this.updateValueDisplayer($el)

    $('.expanding_handler').each (index, el) =>
      $el = $(el)
      $el.on 'click', (event) =>
        this.toggleExpandableBox($el)
        false

    $('input[type=checkbox][data-master]').each (index, el) =>
      $el = $(el)
      $el.on 'click', (e) =>
        this.toggleDependantInputs($el)

  setupPreviewRefresher: ->
    $('#preview-standard-button').on 'click', =>
      this.refreshVideoTagFromSettings('standard')
      false

  setupLightboxTester: ->
    @$lightboxTestButton.on 'click', =>
      this.refreshVideoTagFromSettings('lightbox')

      false

  refreshVideoTagFromSettings: (type) ->
    sublimevideo.unprepare("preview-#{type}")

    switch type
      when 'standard'
        $('#preview-standard').replaceWith(@videoTagHelpers[type].generateVideoCode(id: 'preview-standard'))
      when 'lightbox'
        lightboxCode = @videoTagHelpers[type].generateLightboxCode(href: '#preview-lightbox', id: 'preview-lightbox-button', class: 'blue_button sublime')
        videoCode = @videoTagHelpers[type].generateVideoCode(id: 'preview-lightbox', class: '')

        @$lightboxTestButton.replaceWith($(lightboxCode))
        $('#lightbox-test').replaceWith($(videoCode))

        @$lightboxTestButton = $('#preview-lightbox-button')

        # NEW API
        # sublimevideo.lightbox('lightbox-test-button').open()

    sublimevideo.prepare("preview-#{type}")

  updateValueDisplayer: ($el) ->
    $("##{$el.attr('id')}_value").text Math.round($el.val() * 100) / 100

  toggleExpandableBox: ($el) ->
    $('.expanding_handler').removeClass('expanded')
    $('.expandable').hide()

    $el.toggleClass('expanded')
    $el.siblings('.expandable').toggle()

  toggleDependantInputs: ($el) ->
    $dependantInputs = $("input[data-dependant=#{$el.data('master')}]")

    if $el.attr('checked')?
      $dependantInputs.removeAttr 'disabled'
    else
      $dependantInputs.attr 'disabled', 'disabled'
