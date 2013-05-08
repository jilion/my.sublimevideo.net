class MSVVideoCode.Views.Sharing extends Backbone.View
  template: JST['video_code/templates/sharing']

  initialize: ->
    this._listenToModelsEvents()
    this._initUIHelpers()
    this.render()

  #
  # EVENTS
  #
  events: ->
    'change .kit_setting':             'updateSetting'
    'click input[name=sharing_image]': 'updateSettingsAndToggleImageUrlField'

  updateSetting: (event) ->
    $field = $(event.target)
    this._updateSettingAndRender($field.data('setting'), $field.val())

  updateSettingsAndToggleImageUrlField: (event) ->
    $field = $(event.target)
    $sharingImageUrlField = this.$('#sharing_image_url_field')
    customUrl = !_.contains(['auto', 'poster'], $field.val())
    value = if customUrl then $sharingImageUrlField.val() else $field.val()

    this._updateSettingAndRender($field.data('setting'), value)

    $sharingImageUrlField.toggle(customUrl)

  #
  # BINDINGS
  #
  _listenToModelsEvents: ->
    this.listenTo(MSVVideoCode.kits, 'change', this.render)

  render: ->
    @$el.html this.template()

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

  _updateSettingAndRender: (settingName, value) ->
    MSVVideoCode.video.updateSetting('sharing', settingName, value, MSVVideoCode.kits.selected)
    this.renderStatus()
