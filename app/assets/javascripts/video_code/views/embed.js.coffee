class MSVVideoCode.Views.Embed extends Backbone.View
  template: JST['video_code/templates/embed']

  initialize: ->
    this._initUIHelpers()
    this.render()

  events: ->
    'click input[name=embed_type]':  'updateTypeSettingAndToggleUrlField'
    'change input#embed_url_src':    'updateSetting'
    'change input.kit_setting.size': 'updateSizeSetting'

  updateTypeSettingAndToggleUrlField: (event) ->
    $field = $(event.target)
    this._updateSetting('type', $field.val())
    if $field.val() is 'auto'
      this._updateSetting('url', null)
    else
      this._updateSetting('url', this.$('#embed_url_src').val())
    this.$('#embed_url_section').toggle($field.val() is 'manual')

  updateSetting: (event) ->
    $field = $(event.target)
    this._updateSettingAndRender($field.data('setting'), $field.val())

  updateSizeSetting: (event) ->
    size = this._computeSize(this.$('#embed_width'), this.$('#embed_height'))
    this._updateSettingAndRender($(event.target).data('setting'), _.compact(size).join('x'))

  #
  # BINDINGS
  #
  render: ->
    @$el.html this.template(autoEmbed: @$el.data('plan') is 'auto')

    this

  #
  # PRIVATE
  #
  _initUIHelpers: ->
    @uiHelper = new MSVVideoCode.Helpers.UIAssetHelper('embed_url')

  _computeSize: (widthField, heightField) ->
    size = [parseInt(widthField.val(), 10), parseInt(heightField.val(), 10)]
    size[0] = 200 if _.isNaN(size[0]) || size[0] < 200
    if _.isNaN(size[1])
      size[1] = ''
    else if size[1] < 100
      size[1] = 100

    size

  _updateSettingAndRender: (settingName, value) ->
    this._updateSetting(settingName, value)
    this.render()
    this._renderStatus()

  _updateSetting: (settingName, value) ->
    MSVVideoCode.video.updateSetting('embed', settingName, value, MSVVideoCode.kits.selected)

  _renderStatus: ->
    @uiHelper.hideErrors()

    embedUrl = new MySublimeVideo.Models.Asset(src: MSVVideoCode.video.getSetting('embed', 'url', MSVVideoCode.kits.selected))

    return if embedUrl.srcIsEmpty()

    if !embedUrl.srcIsUrl()
      @uiHelper.renderError('src_invalid')
    else
      @uiHelper.renderValid()
