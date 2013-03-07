class MSVVideoCode.Views.Sharing extends Backbone.View
  template: JST['video_code/templates/sharing']

  events:
    'change .kit_setting':             'updateSetting'
    'click input[name=sharing_image]': 'updateSettingsAndToggleImageUrlField'

  initialize: ->
    this._initUIHelpers()
    @placeholder = $(@el).find('#sharing_settings_fields')

    _.bindAll this, 'render'
    MSVVideoCode.kits.bind 'change', this.render

    this.render()

  #
  # EVENTS
  #
  updateSetting: (event) ->
    $inputField = $(event.target)
    this._updateSettingAndRender($inputField.data('addon'), $inputField.data('setting'), $inputField.val())

  updateSettingsAndToggleImageUrlField: (event) ->
    $inputField = $(event.target)
    $sharingImageUrlField = $('#sharing_image_url_field')
    customUrl = !_.contains(['auto', 'poster'], $inputField.val())
    value = if customUrl then $sharingImageUrlField.val() else $inputField.val()

    this._updateSettingAndRender($inputField.data('addon'), $inputField.data('setting'), value)

    $sharingImageUrlField.toggle(customUrl)

  #
  # BINDINGS
  #
  render: ->
    @placeholder.html this.template()

    this

  renderStatus: ->
    @uiHelper.hideErrors()

    sharingUrl = new MySublimeVideo.Models.Asset(src: MSVVideoCode.video.getSetting('sharing', 'url', MSVVideoCode.kits.selected))
    return if sharingUrl.srcIsEmpty()

    if !sharingUrl.srcIsUrl()
      @uiHelper.renderError('src_invalid')
    else
      @uiHelper.renderValid()

  #
  # PRIVATE
  #
  _initUIHelpers: ->
    @uiHelper = new MSVVideoCode.Helpers.UIAssetHelper('sharing_url')

  _updateSettingAndRender: (addonName, settingName, value) ->
    MSVVideoCode.video.updateSetting(addonName, settingName, value, MSVVideoCode.kits.selected)
    this.renderStatus()
