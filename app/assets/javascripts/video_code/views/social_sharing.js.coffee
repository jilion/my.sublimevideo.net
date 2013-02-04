class MSVVideoCode.Views.SocialSharing extends Backbone.View
  template: JST['video_code/templates/social_sharing']

  events:
    'change .kit_setting': 'updateSettingsFromEvent'
    'click input[name=social_sharing_image]': 'updateSettingsAndToggleImageUrlField'

  initialize: ->
    @uiHelper = new MSVVideoCode.Helpers.UIAssetHelper('sharing_url')

    _.bindAll this, 'render'
    MSVVideoCode.kits.bind 'change', this.render

    this.render()

  #
  # EVENTS
  #
  updateSettingsFromEvent: (event) ->
    $inputField = $(event.target)
    this.updateSetting($inputField.data('addon'), $inputField.data('setting'), $inputField.val())

  updateSettingsAndToggleImageUrlField: (event) ->
    $inputField = $(event.target)
    $socialSharingImageUrlField = $('#social_sharing_image_url_field')
    customUrl = !_.contains(['auto', 'poster'], $inputField.val())
    value = if customUrl
      $socialSharingImageUrlField.val()
    else
      $inputField.val()

    this.updateSetting($inputField.data('addon'), $inputField.data('setting'), value)

    $socialSharingImageUrlField.toggle(customUrl)

  updateSetting: (addonName, settingName, value)->
    MSVVideoCode.video.updateSetting(addonName, settingName, value)
    this.renderStatus()

  #
  # BINDINGS
  #
  render: ->
    $(@el).find('#social_sharing_settings_fields').html this.template
      video: MSVVideoCode.video

    this

  renderStatus: ->
    @uiHelper.hideErrors()

    socialSharingUrl = new MySublimeVideo.Models.Asset(src: MSVVideoCode.video.getSetting('sharing', 'url', MSVVideoCode.kits.selected))

    return if socialSharingUrl.srcIsEmpty()

    if !socialSharingUrl.srcIsUrl()
      @uiHelper.renderError('src_invalid')
    else
      @uiHelper.renderValid()

