class MSVVideoCode.Views.Embed extends Backbone.View
  template: JST['video_code/templates/embed']

  events:
    'click input[name=embed_type]':  'updateTypeSettingAndToggleUrlField'
    'change input#embed_url_src':    'updateSetting'
    'change input.kit_setting.size': 'updateSizeSetting'

  initialize: ->
    this._initUIHelpers()
    @placeholder = $(@el).find('#embed_settings_fields')

    this.render()

  #
  # EVENTS
  #
  updateTypeSettingAndToggleUrlField: (event) ->
    $field = $(event.target)
    this._updateSetting('type', $field.val())
    if $field.val() is 'auto'
      this._updateSetting('url', null)
    else
      this._updateSetting('url', $('#embed_url_src').val())
    $('#embed_url_section').toggle($field.val() is 'manual')

  updateSetting: (event) ->
    $field = $(event.target)
    this._updateSettingAndRender($field.data('setting'), $field.val())

  updateSizeSetting: (event) ->
    $inputField = $(event.target)
    size = [parseInt($('#embed_width').val(), 10), parseInt($('#embed_height').val(), 10)]
    size[0] = 200 if _.isNaN(size[0]) || size[0] < 200
    if _.isNaN(size[1])
      size[1] = ''
    else if size[1] < 100
      size[1] = 100

    this._updateSettingAndRender($inputField.data('setting'), _.compact(size).join('x'))

  #
  # BINDINGS
  #
  render: ->
    @placeholder.html this.template(autoEmbed: @placeholder.data('plan') is 'auto')

    this

  renderStatus: ->
    @uiHelper.hideErrors()

    embedUrl = new MySublimeVideo.Models.Asset(src: MSVVideoCode.video.getSetting('embed', 'url', MSVVideoCode.kits.selected))

    return if embedUrl.srcIsEmpty()

    if !embedUrl.srcIsUrl()
      @uiHelper.renderError('src_invalid')
    else
      @uiHelper.renderValid()

  #
  # PRIVATE
  #
  _initUIHelpers: ->
    @uiHelper = new MSVVideoCode.Helpers.UIAssetHelper('embed_url')

  _updateSettingAndRender: (settingName, value) ->
    this._updateSetting(settingName, value)
    this.render()
    this.renderStatus()

  _updateSetting: (settingName, value) ->
    MSVVideoCode.video.updateSetting('embed', settingName, value, MSVVideoCode.kits.selected)
