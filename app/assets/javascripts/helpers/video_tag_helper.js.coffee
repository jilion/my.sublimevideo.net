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
    _.defaults(options, { addons: ['player', 'videoPlayer', 'controls', 'initial', 'sharing', 'embed', 'logo'] })

    attributes = []
    attributes.push "id=\"#{options['id']}\"" if options['id']?
    attributes.push this.generateClass(options)
    attributes.push this.generatePoster()
    attributes.push this.generateWidthAndHeight(@video.get('width'), @video.get('height'))
    attributes.push this.generateTitle() if @video.get('title')
    attributes.push this.generateStyle()
    attributes.push this.generateDataSettingsAttribute(options)
    attributes.push "preload=\"none\""

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

  generateDataSettingsAttributeContent: (options = {}) ->
    this.generateDataSettings(options)
    _.inject(@dataSettings, ((s, v, k) -> s + "#{k}:#{v};"), '')

  generateDataSettingsAttribute: (options = {}) ->
    this.generateDataSettings(options)
    if _.isEmpty @dataSettings
      ''
    else
      if options['allDataSettingsTogether']
        "data-settings=\"#{this.generateDataSettingsAttributeContent()}\""
      else
        _.inject(@dataSettings, ((a, v, k) -> a.push "data-#{k}=\"#{v}\""; a), []).join(' ')

  generateDataSettings: (opts = {}) ->
    options = {}
    _.extend(options, opts)
    _.defaults(options, { kitReplacement: true, addons: ['player', 'videoPlayer', 'controls', 'initial', 'sharing', 'embed', 'logo'] })

    if options['settings']?
      this.generateDataSettingsFromJSON(options)
    else
      this.generateDataSettingsFromDOM(options['addons'])

    this.replacePlayerKitSettingWithRealPreviewKitIdentifier() if options['kitReplacement']
    this.setDataUID()
    this.setYouTubeID()
    this.setAutoresize()
    this.setAutoplay()

    @dataSettings

  replacePlayerKitSettingWithRealPreviewKitIdentifier: ->
    if @dataSettings['player-kit']?
      selectedOption = $("select[data-addon='player']").find("option[value='#{@dataSettings['player-kit']}']")
      @dataSettings['player-kit'] = selectedOption.data('preview-kit-id')

  setDataUID: ->
    if not @dataSettings['uid']? and @video.get('uid')?
      @dataSettings['uid'] = @video.get('uid')

  setYouTubeID: ->
    if not @dataSettings['youtube-id']? and @video.get('origin') is 'youtube'
      @dataSettings['youtube-id'] = @video.get('youTubeId')

  setAutoresize: ->
    if not @dataSettings['autoresize']? and @video.get('autoresize') isnt 'none'
      @dataSettings['autoresize'] = @video.get('autoresize')

  setAutoplay: ->
    if not @dataSettings['autoplay']? and @video.get('autoplay')
      @dataSettings['autoplay'] = @video.get('autoplay')

  generateClass: (options = {}) ->
    if @video.get('displayInLightbox') or options['class'] is '' then '' else "class=\"sublime\""

  generatePoster: ->
    posterSrc = @video.get('poster').get('src')
    if posterSrc then "poster=\"#{posterSrc}\"" else ''

  generateWidthAndHeight: (width, height) ->
    "width=\"#{width}\" height=\"#{height}\""

  generateStyle: ->
    if @video.get('displayInLightbox') then "style=\"display:none\"" else ''

  generateTitle: ->
    "title=\"#{@video.get('title')}\""

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
    (if _.contains(['videoPlayer', 'lightbox'], addonName)
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
    @dataSettings[dataSettingName] = currentValue.toString().split(',').join(' ')
