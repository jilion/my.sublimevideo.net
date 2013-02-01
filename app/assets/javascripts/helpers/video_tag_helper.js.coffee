class MySublimeVideo.Helpers.VideoTagHelper
  constructor: (@video, @options = {}) ->
    _.defaults(@options, { forceSettings: false })
    @extraSpaces = ''

  generatePlayerCode: (options = {}) ->
    code = if @video.get('displayInLightbox') then this.generateLightboxCode(options) else ''

    code + this.generateVideoCode(options)

  generateVideoCode: (opts = {}) ->
    options = {}
    _.extend(options, opts)
    _.defaults(options, { addons: ['player', 'video_player', 'controls', 'initial', 'sharing', 'embed', 'logo'] })

    attributes = []
    attributes.push "id=\"#{options['id']}\"" if options['id']?
    attributes.push this.generateClass(options)
    attributes.push this.generatePoster()
    attributes.push this.generateWidthAndHeight(@video.get('width'), @video.get('height'))
    attributes.push "data-youtube-id=\"#{@video.get('youTubeId')}\"" if @video.get('origin') is 'youtube'
    attributes.push "data-autoresize=\"#{@video.get('autoresize')}\""
    attributes.push this.generateDataSettingsAttribute(options)
    attributes.push this.generateDataUIDAndName()
    attributes.push this.generateStyle()
    attributes.push "preload=\"none\""
    attributes.push "autoplay" if @video.get('autoplay')

    code = "#{@extraSpaces}<video #{_.compact(attributes).join(' ')}>\n"
    code += this.generateSources() unless @video.get('origin') is 'youtube'

    code + "#{@extraSpaces}</video>"

  generateSources: ->
    _.reduce @video.get('sources').sortedSources(@video.get('startWithHd')), (code, source) =>
      code += "#{@extraSpaces}  <source src=\"#{source.get('src')}\" #{this.generateDataQuality(source)}/>\n"
    , ''

  generateLightboxCode: (opts = {}) ->
    options = {}
    _.extend(options, opts)
    _.defaults(options, { addons: ['lightbox'], href: options['id'] })

    attributes = []
    attributes.push "href=\"##{options['href']}\""
    attributes.push "id=\"#{options['lightboxId']}\"" if options['lightboxId']?
    attributes.push "class=\"#{options['lightboxClass'] or 'sublime'}\""
    attributes.push "style=\"#{options['lightboxStyle']}\"" if options['lightboxStyle']?
    attributes.push this.generateDataSettingsAttribute(options)
    code = "<a #{_.compact(attributes).join(' ')}>\n  "
    code += this.getLightboxTriggerContent()
    code + "\n</a>\n"

  getLightboxTriggerContent: ->
    if @video.get('thumbnail').get('initialLink') is 'image'
      attributes = []
      attributes.push "src=\"#{@video.get('thumbnail').get('src')}\""
      attributes.push this.generateWidthAndHeight(@video.get('thumbnail').get('thumbWidth'), @video.get('thumbnail').get('thumbHeight'))
      "<img #{_.compact(attributes).join(' ')} />"
    else
      "#{@video.get('thumbnail').get('src')}"

  generateDataSettingsAttribute: (options = {}) ->
    this.generateDataSettings(options)
    if _.isEmpty @dataSettings
      ''
    else
      if options['contentOnly']
        _.inject(@dataSettings, ((s, v, k) -> s + "#{k}:#{v};"), '')
      else
        _.inject(@dataSettings, ((a, v, k) -> a.push "data-#{k}=\"#{v}\""; a), []).join(' ')

  generateDataSettings: (opts = {}) ->
    options = {}
    _.extend(options, opts)
    _.defaults(options, { addons: ['player', 'video_player', 'controls', 'initial', 'sharing', 'embed', 'logo'] })

    if options['settings']?
      this.generateDataSettingsFromJSON(options)
    else
      this.generateDataSettingsFromDOM(options['addons'])

    this.replacePlayerKitSettingWithRealPreviewKitIdentifier()

    @dataSettings

  replacePlayerKitSettingWithRealPreviewKitIdentifier: ->
    if @dataSettings['player-kit']?
      selectedOption = $("select[data-addon='player']").find("option[value='#{@dataSettings['player-kit']}']")
      @dataSettings['player-kit'] = selectedOption.data('kit-id')

  generateClass: (options = {}) ->
    if @video.get('displayInLightbox') or options['class'] is '' then '' else "class=\"sublime\""

  generatePoster: ->
    posterSrc = @video.get('poster').get('src')
    if posterSrc then "poster=\"#{posterSrc}\"" else ''

  generateWidthAndHeight: (width, height) ->
    "width=\"#{width}\" height=\"#{height}\""

  generateStyle: ->
    if @video.get('displayInLightbox') then "style=\"display:none\"" else ''

  generateDataUIDAndName: ->
    dataUIDAndName = []
    if dataUID = @video.get('dataUID')
      dataUIDAndName.push "data-uid=\"#{dataUID}\""
    if dataName = @video.get('dataName')
      dataUIDAndName.push "data-name=\"#{dataName}\""

    dataUIDAndName.join(' ')

  generateDataQuality: (source) ->
    if source.needDataQualityAttribute() then "data-quality=\"#{source.get('quality')}\" " else ''

  generateDataSettingsFromJSON: (options) ->
    @dataSettings = {}
    for addonName in options['addons']
      if options['settings'][addonName]?
        _.each options['settings'][addonName], (settingValue, settingName) =>
          dataSettingName = this.getDataSettingName(addonName, settingName)
          if _.contains([true, false], settingValue)
            this.processCheckBoxInput(dataSettingName, settingValue, null)
          else
            this.processInputWithValue(dataSettingName, settingValue, null)

  generateDataSettingsFromDOM: (addons) ->
    @dataSettings = {}
    for addonName in addons
      $("input.previewable[data-addon='#{addonName}'], " +
      "select[data-addon='#{addonName}'], " +
      "input[type=radio][data-addon='#{addonName}']:checked").each (index, el) =>
        $el = $(el)
        currentValue    = $el.val()
        defaultValue    = this.getDefaultValue($el)
        dataSettingName = this.getDataSettingName(addonName, $el.data('setting'))

        switch $el.attr('type')
          when 'range'
            this.processRangeInput(dataSettingName, currentValue, defaultValue)
          when 'checkbox'
            this.processCheckBoxInput(dataSettingName, $el.prop('checked'), defaultValue)
          else
            this.processInputWithValue(dataSettingName, currentValue, defaultValue)

  getDefaultValue: ($el) ->
    defaultValue = $el.data('default')

    switch defaultValue
      when 'true'
        true
      when 'false'
        false
      when null
        ''
      else
        defaultValue

  getDataSettingName: (addonName, settingName) ->
    (if _.contains(['video_player', 'lightbox'], addonName)
      settingName
    else
      "#{addonName}-#{settingName}"
    ).underscore().dasherize()

  processRangeInput: (dataSettingName, currentValue, defaultValue) ->
    currentValue = Math.round(currentValue * 100) / 100
    this.pushDataSetting(dataSettingName, currentValue) if @options['forceSettings'] or (currentValue isnt defaultValue)

  processCheckBoxInput: (dataSettingName, currentValue, defaultValue) ->
    if @options['forceSettings'] or (currentValue isnt defaultValue)
      this.pushDataSetting(dataSettingName, currentValue)

  processInputWithValue: (dataSettingName, currentValue, defaultValue) ->
    if @options['forceSettings'] or (currentValue isnt defaultValue)
      this.pushDataSetting(dataSettingName, currentValue)

  pushDataSetting: (dataSettingName, currentValue) ->
    @dataSettings[dataSettingName] = if $.isArray(currentValue) then currentValue.join(' ') else currentValue.toString()
