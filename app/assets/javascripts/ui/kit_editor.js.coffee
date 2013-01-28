class MySublimeVideo.UI.KitEditor
  constructor: ->
    sublime.ready =>
      this.setup()

  setup: ->
    new MySublimeVideo.UI.DependantInputs
    this.setupModels()
    this.setupHelpers()
    this.setupInputsObservers()
    this.setupSocialSharingButtonsSelector()
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
      siteToken = document.location.pathname.match(/(assistant|sites)\/([\w]{8})/)[2]
      md = document.location.pathname.match(/sites\/[\w]{8}\/players\/(\d+)/)
      kitId = if md
        md[1]
      else
        1
      expandParam = ''
      if ($handler = $('h4.expanding_handler.expanded')).exists()
        expandParam = "&expand=#{$handler.attr('id')}"

      $.ajax(
        url: "/sites/#{siteToken}/players/#{kitId}/fields?design_id=#{$designSelector.val()}#{expandParam}"
      ).done (data) =>
        MySublimeVideo.prepareVideosAndLightboxes()
        this.setup()
      false

    this.setupAllInputsObserver()

    this.setupRangeInputsObserver()

    this.setupLogoTypeInputObserver()
    this.setupLogoUrlInputObserver()

  setupAllInputsObserver: ->
    $("input[type=checkbox], input[type=radio], input[type=range], input[type=text], input[type=hidden]").each (index, el) =>
      $(el).on 'change', =>
        this.refreshVideoTagFromSettings()
        false

  setupRangeInputsObserver: ->
    $('input[type=range]').each (index, el) =>
      $el = $(el)
      $el.on 'change', =>
        this.updateValueDisplayer($el)

  setupLogoTypeInputObserver: ->
    $('input[name="kit[settings][logo][type]"]').on 'change', (e) =>
      $el = $(e.target)
      if $el.val() is 'custom'
        $('.custom_logo_fields').show()
        $('.standard_logo_fields').hide()
      else
        $('.custom_logo_fields').hide()
        $('.standard_logo_fields').show()

  setupLogoUrlInputObserver: ->
    $('#kit_setting-logo-image_url').on 'change', (e) =>
      this.refreshVideoTagFromSettings()

  setupSocialSharingButtonsSelector: ->
    socialSharingButtonsInputFieldId = 'kit_setting-social_sharing-buttons'
    $('#social_sharing_active_buttons, #social_sharing_inactive_buttons').disableSelection().sortable
      connectWith: '.drop_zone'
      over: (event, ui) =>
        this.toggleReceiveDropZoneHighlight(ui.item)
      receive: (event, ui) =>
        ui.item.toggleClass('enabled').toggleClass('disabled')
      stop: (event, ui) =>
        $('#social_sharing_active_buttons, #social_sharing_inactive_buttons').removeClass('highlight')
        buttons = $('#social_sharing_active_buttons').sortable('toArray', { attribute: 'data-value' }).join(' ')
        $("##{socialSharingButtonsInputFieldId}").val(buttons)
        this.refreshVideoTagFromSettings()

  toggleReceiveDropZoneHighlight: ($item) ->
    if $item.parent().attr('id') is 'social_sharing_active_buttons'
      $('#social_sharing_inactive_buttons').toggleClass('highlight')
    else
      $('#social_sharing_active_buttons').toggleClass('highlight')

  refreshVideoTagFromSettings: ->
    sublime.reprepareVideo 'standard', @videoTagHelpers['standard'].generateDataSettings()

    if lightbox = sublime.lightbox('lightbox-trigger')
      sublime.unprepare('lightbox-trigger')

      lightboxDataSettings = @videoTagHelpers['lightbox'].generateDataSettingsAttribute(['lightbox'], contentOnly: true)
      $('#lightbox-trigger').attr('data-settings', lightboxDataSettings)

      $('#lightbox').attr('data-settings', @videoTagHelpers['standard'].generateDataSettingsAttribute([], contentOnly: true))

      sublime.prepare('lightbox-trigger')

  updateValueDisplayer: ($el) ->
    $el.siblings('.value_displayer').text Math.round($el.val() * 100) / 100
