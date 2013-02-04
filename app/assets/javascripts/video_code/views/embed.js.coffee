class MSVVideoCode.Views.Embed extends Backbone.View
  template: JST['video_code/templates/embed']

  events:
    'change .kit_setting': 'updateSettingsFromEvent'

  initialize: ->
    @uiHelper = new MSVVideoCode.Helpers.UIAssetHelper('embed_url')

    _.bindAll this, 'render'
    MSVVideoCode.kits.bind 'change', this.render

    this.render()

  #
  # EVENTS
  #
  updateSettingsFromEvent: (event) ->
    $inputField = $(event.target)
    this.updateSetting($inputField.data('addon'), $inputField.data('setting'), $inputField.val())

  updateSetting: (addonName, settingName, value)->
    MSVVideoCode.video.updateSetting(addonName, settingName, value)
    this.renderStatus()

  #
  # BINDINGS
  #
  render: ->
    $(@el).find('#embed_settings_fields').html this.template
      video: MSVVideoCode.video

    this

  renderStatus: ->
    @uiHelper.hideErrors()

    embedUrl = new MySublimeVideo.Models.Asset(src: MSVVideoCode.video.getSetting('embed', 'url', MSVVideoCode.kits.selected))

    return if embedUrl.srcIsEmpty()

    if !embedUrl.srcIsUrl()
      @uiHelper.renderError('src_invalid')
    else
      @uiHelper.renderValid()

