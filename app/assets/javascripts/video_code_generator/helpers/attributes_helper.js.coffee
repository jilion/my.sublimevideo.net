class MSVVideoCodeGenerator.Helpers.AttributesHelper

  constructor: (@builder, @video) ->
    @builderClass = @builder.get('builderClass')

  generateVideoCode: ->
    code = if @builderClass is 'lightbox' then this.generateLightboxCode() else ''
    extraSpaces = if @builderClass is 'iframe_embed' then "    " else ""

    attributes = []
    attributes.push "class=\"#{@video.get('classes')}\""
    attributes.push this.generatePosterAttribute()
    attributes.push this.generateWidthAndHeightAttributes(@video.width(), @video.height()) unless @builderClass is 'iframe_embed'
    attributes.push this.generateDataSettings(['video_player', 'controls', 'initial', 'sharing', 'image_viewer', 'sv_logo', 'api', 'stats'])
    attributes.push this.generateDataName() + this.generateDataUID()
    attributes.push this.generateStyleAttribute()
    attributes.push "preload=\"none\""

    code += "#{extraSpaces}<video #{_.compact(attributes).join(' ')}>\n"
    for source in @video.get('sources').sortedSources(@builder.get('startWithHd'))
      attributes = []
      attributes.push "src=\"#{source.get('src')}\""
      attributes.push this.generateDataQuality(source)
      code += "#{extraSpaces}  <source #{_.compact(attributes).join(' ')}/>\n"
    code += "#{extraSpaces}</video>"

  generateLightboxCode: ->
    attributes = []
    attributes.push "href=\"#{@video.get('sources').mp4Mobile().get('src')}\""
    attributes.push "class=\"sublime\""
    attributes.push this.generateDataSettings(['lightbox'])
    code = "<a #{_.compact(attributes).join(' ')}>\n  "

    if @video.get('thumbnail').get('initialLink') is 'image'
      attributes = []
      attributes.push "src=\"#{@video.get('thumbnail').get('src')}\""
      attributes.push this.generateWidthAndHeightAttributes(@video.get('thumbnail').get('thumbWidth'), @video.get('thumbnail').get('thumbHeight'))
      code += "<img #{_.compact(attributes).join(' ')} />"
    else
      code += "#{@video.get('thumbnail').get('src')}"
    code + "\n</a>\n"

  generateDataSettings: (addons) ->
    dataSettings = this.generateDataSettingsArray(addons)

    if _.isEmpty dataSettings then '' else "data-settings=\"#{dataSettings.join('; ')}\""

  generatePosterAttribute: ->
    posterSrc = @video.get('poster').get('src')
    if posterSrc then "poster=\"#{posterSrc}\"" else ''

  generateWidthAndHeightAttributes: (width, height) ->
    "width=\"#{width}\" height=\"#{height}\""

  generateStyleAttribute: ->
    if _.include(['lightbox', 'iframe_embed'], @builderClass) then "style=\"display:none\"" else ''

  generateDataName: ->
    dataName = @video.get('sources').mp4Base().get('dataName')
    if dataName then "data-name=\"#{dataName}\"" else ''

  generateDataUID: ->
    dataUID = @video.get('sources').mp4Base().get('dataUID')
    if dataUID then "data-uid=\"#{dataUID}\"" else ''

  generateDataQuality: (source) ->
    if source.needDataQualityAttribute() then "data-quality=\"#{source.get('quality')}\" " else ''

  generateDataSettingsArray: (addons) ->
    @dataSettings = []

    for addonName in addons
      $("input[type=checkbox][data-addon='#{addonName}'], input[type=radio][data-addon='#{addonName}']:checked, input[type=range][data-addon='#{addonName}'], input[type=text][data-addon='#{addonName}']").each (index, el) =>
        $el = $(el)
        currentValue    = $el.val()
        defaultValue    = this.getDefaultValue($el)
        dataSettingName = this.getDataSettingName(addonName, $el.attr('id'))

        switch this.getInputType($el)
          when 'range'    then this.processRangeInput(dataSettingName, currentValue, defaultValue)
          when 'radio'    then this.processRadioInput(dataSettingName, currentValue, defaultValue)
          when 'checkbox' then this.processCheckBoxAndTextInput(dataSettingName, $el.attr('checked')?, defaultValue)
          when 'text'     then this.processCheckBoxAndTextInput(dataSettingName, currentValue, defaultValue)
    @dataSettings

  getInputType: ($el) ->
    $el.attr('type')

  getDefaultValue: ($el) ->
    defaultValue = $el.data('default')

    if defaultValue is null then '' else defaultValue

  getDataSettingName: (addonName, id) ->
    idParts = id.split('-')
    dataSettingName = (if _.contains(['video_player', 'lightbox'], addonName) then idParts[2] else "#{idParts[1]}-#{idParts[2]}").underscore().dasherize()

  processRangeInput: (dataSettingName, currentValue, defaultValue) ->
    currentValue = Math.round(currentValue * 100) / 100
    this.pushDataSetting(dataSettingName, currentValue) if currentValue isnt defaultValue

  processRadioInput: (dataSettingName, currentValue, defaultValue) ->
    this.pushDataSetting(dataSettingName, currentValue) unless defaultValue

  processCheckBoxAndTextInput: (dataSettingName, currentValue, defaultValue) ->
    this.pushDataSetting(dataSettingName, currentValue) unless currentValue is defaultValue

  pushDataSetting: (dataSettingName, currentValue) ->
    @dataSettings.push "#{dataSettingName.replace(/-visibility/, '')}: #{currentValue.toString().underscore().dasherize()}"
