class MySublimeVideo.UI.KitEditor
  constructor: ->
    sublimevideo.ready =>
      this.setup()

  setup: ->
    new MySublimeVideo.UI.DependantInputs
    this.setupModels()
    this.setupHelpers()
    this.setupInputsObservers()

    this.refreshVideoTagFromSettings()

  setupModels: ->
    @video    = new MySublimeVideo.Models.Video
    @lightbox = new MySublimeVideo.Models.Video(displayInLightbox: true)

  setupHelpers: ->
    @videoTagHelpers =
      standard: new MySublimeVideo.Helpers.VideoTagHelper(@video, forceSettings: true)
      lightbox: new MySublimeVideo.Helpers.VideoTagHelper(@lightbox, forceSettings: true)

  setupInputsObservers: ->
    $designSelector = $("select#kit_app_design_id")
    $designSelector.one 'change', =>
      this.refreshVideoTagFromSettings()
      $.ajax(
        url: "#{document.location.pathname.replace(/new|edit/, 'fields')}?design_id=#{$designSelector.val()}"
      ).done (data) =>
        MySublimeVideo.prepareVideosAndLightboxes()
        this.setup()
      false

    $("input[type=checkbox], input[type=radio], input[type=range], input[type=text], input[type=hidden]").each (index, el) =>
      $(el).on 'change', =>
        this.refreshVideoTagFromSettings()
        false

    $('input[type=range]').each (index, el) =>
      $el = $(el)
      $el.on 'change', =>
        this.updateValueDisplayer($el)

    $('input[name="kit[addons][logo][type]"]').on 'change', (e) =>
      $el = $(e.target)
      if $el.val() is 'custom'
        $('.custom_logo_fields').show()
        $('.standard_logo_fields').hide()
      else
        $('.custom_logo_fields').hide()
        $('.standard_logo_fields').show()
      this.refreshVideoTagFromSettings()

    $('#kit_setting-logo-image_url').on 'change', (e) =>
      this.refreshVideoTagFromSettings()

  refreshVideoTagFromSettings: ->
    sublime.reprepareVideo 'standard', @videoTagHelpers['standard'].generateDataSettings()

    if lightbox = sublime.lightbox('lightbox-trigger')
      sublime.unprepare('lightbox-trigger')

      lightboxDataSettings = @videoTagHelpers['lightbox'].generateDataSettingsAttribute(['lightbox'], contentOnly: true)
      $('#lightbox-trigger').attr('data-settings', lightboxDataSettings)

      $('#lightbox').attr('data-settings', @videoTagHelpers['standard'].generateDataSettingsAttribute([], contentOnly: true))

      sublime.prepare('lightbox-trigger')

  updateValueDisplayer: ($el) ->
    $("##{$el.attr('id')}_value").text Math.round($el.val() * 100) / 100
