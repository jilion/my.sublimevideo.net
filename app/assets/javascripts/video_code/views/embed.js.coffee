class MSVVideoCode.Views.Embed extends Backbone.View
  template: JST['video_code/templates/embed']

  events:
    'change input#embed_url_src.kit_setting': 'updateUrlSetting'
    'change input.kit_setting.size': 'updateSizeSetting'

  initialize: ->
    @uiHelper = new MSVVideoCode.Helpers.UIAssetHelper('embed_url')

    _.bindAll this, 'render'
    MSVVideoCode.kits.bind 'change', this.render

    this.render()

  #
  # EVENTS
  #
  updateUrlSetting: (event) ->
    $inputField = $(event.target)
    this.updateSetting($inputField.data('addon'), $inputField.data('setting'), $inputField.val())

  updateSizeSetting: (event) ->
    $inputField = $(event.target)
    size = [$('#embed_width').val(), $('#embed_height').val()].join('x').replace(/x$/, '')
    this.updateSetting($inputField.data('addon'), $inputField.data('setting'), size)

  updateSetting: (addonName, settingName, value) ->
    MSVVideoCode.video.updateSetting(addonName, settingName, value)
    this.renderStatus()

  #
  # BINDINGS
  #
  render: ->
    $(@el).find('#embed_settings_fields').html this.template(video: MSVVideoCode.video)

    this

  renderStatus: ->
    @uiHelper.hideErrors()

    embedUrl = new MySublimeVideo.Models.Asset(src: MSVVideoCode.video.getSetting('embed', 'url', MSVVideoCode.kits.selected))

    return if embedUrl.srcIsEmpty()

    if !embedUrl.srcIsUrl()
      @uiHelper.renderError('src_invalid')
    else
      @uiHelper.renderValid()

