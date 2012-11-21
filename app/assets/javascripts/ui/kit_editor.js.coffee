class MySublimeVideo.UI.KitEditor
  constructor: ->
    new MySublimeVideo.UI.DependantInputs
    this.setupModels()
    this.setupHelpers()
    this.setupInputsObservers()
    this.setupLightboxTester()

    sublimevideo.ready =>
      this.refreshVideoTagFromSettings('standard')

  setupModels: ->
    @video    = new MySublimeVideo.Models.Video
    @lightbox = new MySublimeVideo.Models.Video(displayInLightbox: true)

  setupHelpers: ->
    @videoTagHelpers =
      standard: new MySublimeVideo.Helpers.VideoTagHelper(@video, forceSettings: true)
      lightbox: new MySublimeVideo.Helpers.VideoTagHelper(@lightbox, forceSettings: true)

  setupInputsObservers: ->
    $("select, input[type=checkbox], input[type=radio], input[type=range], input[type=text], input[type=hidden]").each (index, el) =>
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
      this.refreshVideoTagFromSettings('standard')

    $('#kit_setting-logo-image_url').on 'change', (e) =>
      this.refreshVideoTagFromSettings('standard')

  setupLightboxTester: ->
    $('#preview-lightbox-button').on 'click', (event) =>
      this.refreshVideoTagFromSettings('lightbox')
      false

  refreshVideoTagFromSettings: (type) ->

    switch type
      when 'standard'
        console.log @videoTagHelpers[type].generateDataSettings()
        sublime.reprepareVideo 'standard', @videoTagHelpers[type].generateDataSettings()

      when 'lightbox'
        if lightbox = sublime.lightbox('lightbox-trigger')
          lightbox.close()
          sublime.reprepareVideo 'lightbox', @videoTagHelpers[type].generateDataSettings()
          dataSettings = @videoTagHelpers[type].generateDataSettingsAttribute(['lightbox'], contentOnly: true)
          $('a#lightbox-trigger').attr('data-settings', dataSettings)
          lightbox.open()

  updateValueDisplayer: ($el) ->
    $("##{$el.attr('id')}_value").text Math.round($el.val() * 100) / 100
