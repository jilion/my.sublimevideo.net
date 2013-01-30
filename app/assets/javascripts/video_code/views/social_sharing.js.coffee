class MSVVideoCode.Views.SocialSharing extends Backbone.View
  template: JST['video_code/templates/social_sharing']

  events:
    'change .kit_setting': 'updateSettingsFromEvent'
    'click input[name=social_sharing_image]': 'updateSettingsAndToggleImageUrlField'

  initialize: ->
    @videoTagHelper = new MySublimeVideo.Helpers.VideoTagHelper(MSVVideoCode.video)

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

  #
  # BINDINGS
  #
  render: ->
    $(@el).find('#social_sharing_settings_fields').html this.template
      video: MSVVideoCode.video
    $(@el).show()

    this
