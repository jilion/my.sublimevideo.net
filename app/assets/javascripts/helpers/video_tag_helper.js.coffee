class MySublimeVideo.Helpers.VideoTagHelper

  constructor: (@video, @options = {}) ->
    _.defaults(@options, { type: 'standard', startWithHd: false, forceSettings: false })
    @extraSpaces = if @options['type'] is 'iframe_embed' then '    ' else ''

  generatePlayerCode: ->
    code  = if @options['type'] is 'lightbox' then this.generateLightboxCode() else ''

    code + this.generateVideoCode()

  generateVideoCode: (options = {}) ->
    _.defaults(options, { class: @video.get('classes') })

    attributes = []
    attributes.push "id=\"#{options['id']}\"" if options['id']?
    attributes.push "class=\"#{options['class']}\"" if options['class']?
    attributes.push this.generatePosterAttribute()
    attributes.push this.generateWidthAndHeight(@video.width(), @video.height()) unless @options['type'] is 'iframe_embed'
    attributes.push this.generateDataSettings(['video_player', 'controls', 'initial', 'sharing', 'image_viewer', 'logo', 'api', 'stats'])
    attributes.push this.generateDataName() + this.generateDataUID()
    attributes.push this.generateStyle()
    attributes.push "preload=\"none\""

    code = "#{@extraSpaces}<video #{_.compact(attributes).join(' ')}>\n"
    code += this.generateSources()

    code + "#{@extraSpaces}</video>"

  generateSources: ->
    _.reduce @video.get('sources').sortedSources(@options['startWithHd']), (code, source) =>
      code += "#{@extraSpaces}  <source src=\"#{source.get('src')}\" #{this.generateDataQuality(source)}/>\n"
    , ''

  generateLightboxCode: (options = {}) ->
    _.defaults(options, { href: @video.get('sources').mp4Mobile().get('src'), class: 'sublime' })

    attributes = []
    attributes.push "href=\"#{options['href']}\""
    attributes.push "id=\"#{options['id']}\"" if options['id']?
    attributes.push "class=\"#{options['class']}\""
    attributes.push this.generateDataSettings(['lightbox'])
    code = "<a #{_.compact(attributes).join(' ')}>\n  "

    if @video.get('thumbnail').get('initialLink') is 'image'
      attributes = []
      attributes.push "src=\"#{@video.get('thumbnail').get('src')}\""
      attributes.push this.generateWidthAndHeight(@video.get('thumbnail').get('thumbWidth'), @video.get('thumbnail').get('thumbHeight'))
      code += "<img #{_.compact(attributes).join(' ')} />"
    else
      code += "#{@video.get('thumbnail').get('src')}"
    code + "\n</a>\n"

  generateDataSettings: (addons) ->
    this.generateDataSettingsArray(addons)

    if _.isEmpty @dataSettings
      ''
    else
      "data-settings=\"#{_.inject(@dataSettings, ((s, v, k) -> s + "#{k}:#{v};"), '')}\""

  generatePosterAttribute: ->
    posterSrc = @video.get('poster').get('src')
    if posterSrc then "poster=\"#{posterSrc}\"" else ''

  generateWidthAndHeight: (width, height) ->
    "width=\"#{width}\" height=\"#{height}\""

  generateStyle: ->
    if _.include(['lightbox', 'iframe_embed'], @options['type']) then "style=\"display:none\"" else ''

  generateDataName: ->
    dataName = @video.get('sources').mp4Base().get('dataName')
    if dataName then "data-name=\"#{dataName}\"" else ''

  generateDataUID: ->
    dataUID = @video.get('sources').mp4Base().get('dataUID')
    if dataUID then "data-uid=\"#{dataUID}\"" else ''

  generateDataQuality: (source) ->
    if source.needDataQualityAttribute() then "data-quality=\"#{source.get('quality')}\" " else ''

  generateDataSettingsArray: (addons) ->
    @dataSettings = {}

    for addonName in addons
      $("input[type=checkbox][data-addon='#{addonName}'], " +
      "input[type=radio][data-addon='#{addonName}']:checked, " +
      "input[type=range][data-addon='#{addonName}'], " +
      "input[type=text][data-addon='#{addonName}']").each (index, el) =>
        $el = $(el)
        currentValue    = $el.val()
        defaultValue    = this.getDefaultValue($el)
        dataSettingName = this.getDataSettingName(addonName, $el.data('setting'))

        switch this.getInputType($el)
          when 'range'    then this.processRangeInput(dataSettingName, currentValue, defaultValue)
          when 'radio'    then this.processRadioInput(dataSettingName, currentValue, defaultValue)
          when 'checkbox' then this.processCheckBoxAndTextInput(dataSettingName, $el.attr('checked')?, defaultValue)
          when 'text'     then this.processCheckBoxAndTextInput(dataSettingName, currentValue, defaultValue)

  getInputType: ($el) ->
    $el.attr('type')

  getDefaultValue: ($el) ->
    defaultValue = $el.data('default')

    if defaultValue is null then '' else defaultValue

  getDataSettingName: (addonName, settingName) ->
    (if _.contains(['video_player', 'lightbox'], addonName)
      settingName
    else
      "#{addonName}-#{settingName}"
    ).underscore().dasherize()

  processRangeInput: (dataSettingName, currentValue, defaultValue) ->
    currentValue = Math.round(currentValue * 100) / 100
    this.pushDataSetting(dataSettingName, currentValue) if @options['forceSettings'] or (currentValue isnt defaultValue)

  processRadioInput: (dataSettingName, currentValue, defaultValue) ->
    this.pushDataSetting(dataSettingName, currentValue) if @options['forceSettings'] or !defaultValue

  processCheckBoxAndTextInput: (dataSettingName, currentValue, defaultValue) ->
    if !currentValue and (@options['forceSettings'] or (currentValue isnt defaultValue))
      this.pushDataSetting(dataSettingName, 'none')

  pushDataSetting: (dataSettingName, currentValue) ->
    if !/(-enable|enable-|-visibility)/.test(dataSettingName) or @dataSettings[dataSettingName.replace(/(-enable|enable-|-visibility)/, '')] isnt 'none'
      @dataSettings[dataSettingName.replace(/(-enable|enable-|-visibility)/, '')] = currentValue.toString().underscore().dasherize()
