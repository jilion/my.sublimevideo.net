describe 'MySublimeVideo.Helpers.VideoTagHelper', ->
  describe 'getDataSettingName: (addonName, settingName)', ->
    beforeEach ->
      @video  = new MySublimeVideo.Models.Video
      @helper = new MySublimeVideo.Helpers.VideoTagHelper(@video)

    it 'remove addon name if "video_player"', ->
      expect(@helper.getDataSettingName('video_player', 'fullmode_priority')).toEqual('fullmode-priority')

    it 'remove addon name if "lightbox"', ->
      expect(@helper.getDataSettingName('lightbox', 'overlay_opacity')).toEqual('overlay-opacity')

    it 'replace _ with - and join addon name and setting name', ->
      expect(@helper.getDataSettingName('initial', 'enable_overlay')).toEqual('initial-enable-overlay')

  describe 'processCheckBoxInput: (dataSettingName, currentValue, defaultValue)', ->
    describe 'options["forceSettings"] is false', ->
      beforeEach ->
        @video  = new MySublimeVideo.Models.Video
        @helper = new MySublimeVideo.Helpers.VideoTagHelper(@video)
        @helper.dataSettings = {}

      it 'set data setting to null', ->
        expect(@helper.processCheckBoxInput('initial-overlay-enable', true, false))
        expect(@helper.dataSettings['initial-overlay']).toEqual(null)

      it 'set data setting to "none"', ->
        expect(@helper.processCheckBoxInput('initial-overlay-enable', false, true))
        expect(@helper.dataSettings['initial-overlay']).toEqual('none')

      it 'set data setting to true', ->
        expect(@helper.processCheckBoxInput('fullmode-priority', true, false))
        expect(@helper.dataSettings['fullmode-priority']).toEqual('true')

      it 'set data setting to false', ->
        expect(@helper.processCheckBoxInput('fullmode-priority', false, true))
        expect(@helper.dataSettings['fullmode-priority']).toEqual('false')

      it 'do not set data setting to true', ->
        expect(@helper.processCheckBoxInput('fullmode-priority', true, true))
        expect(@helper.dataSettings['fullmode-priority']).toEqual(null)

      it 'do not set data setting to false', ->
        expect(@helper.processCheckBoxInput('fullmode-priority', false, false))
        expect(@helper.dataSettings['fullmode-priority']).toEqual(null)

    describe 'options["forceSettings"] is true', ->
      beforeEach ->
        @video  = new MySublimeVideo.Models.Video
        @helper = new MySublimeVideo.Helpers.VideoTagHelper(@video, forceSettings: true)
        @helper.dataSettings = {}

      it 'set data setting to null', ->
        expect(@helper.processCheckBoxInput('initial-overlay-enable', true, false))
        expect(@helper.dataSettings['initial-overlay']).toEqual(null)

      it 'set data setting to "none"', ->
        expect(@helper.processCheckBoxInput('initial-overlay-enable', false, true))
        expect(@helper.dataSettings['initial-overlay']).toEqual('none')

      it 'set data setting to true', ->
        expect(@helper.processCheckBoxInput('fullmode-priority', true, false))
        expect(@helper.dataSettings['fullmode-priority']).toEqual('true')

      it 'set data setting to false', ->
        expect(@helper.processCheckBoxInput('fullmode-priority', false, true))
        expect(@helper.dataSettings['fullmode-priority']).toEqual('false')

      it 'do not set data setting to true', ->
        expect(@helper.processCheckBoxInput('fullmode-priority', true, true))
        expect(@helper.dataSettings['fullmode-priority']).toEqual('true')

      it 'do not set data setting to false', ->
        expect(@helper.processCheckBoxInput('fullmode-priority', false, false))
        expect(@helper.dataSettings['fullmode-priority']).toEqual('false')

  describe 'pushDataSetting: (dataSettingName, currentValue)', ->
    describe 'standard video', ->
      beforeEach ->
        @video  = new MySublimeVideo.Models.Video
        @helper = new MySublimeVideo.Helpers.VideoTagHelper(@video)
        @helper.dataSettings = {}

      it 'remove -enable when needed', ->
        @helper.pushDataSetting('initial-overlay-enable', 'none')
        expect(@helper.dataSettings['initial-overlay']).toEqual('none')

      it 'remove -visibility when needed', ->
        @helper.pushDataSetting('initial-overlay-visibility', 'visible')
        console.log @helper.dataSettings
        expect(@helper.dataSettings['initial-overlay-visibility']).toEqual('visible')

      it 'do not push -visibility if root setting is "none"', ->
        @helper.dataSettings['initial-overlay'] = 'none'
        @helper.pushDataSetting('initial-overlay-visibility', 'visible')
        expect(@helper.dataSettings['initial-overlay-visibility']).toEqual(null)

    describe 'lightbox video', ->
      beforeEach ->
        @video  = new MySublimeVideo.Models.Video(displayInLightbox: true)
        @helper = new MySublimeVideo.Helpers.VideoTagHelper(@video)
        @helper.dataSettings = {}

      it 'remove enable- when needed', ->
        @helper.pushDataSetting('enable-close-button', 'none')
        expect(@helper.dataSettings['close-button']).toEqual('none')

      it 'do not push -visibility if root setting is "none"', ->
        @helper.dataSettings['close-button'] = 'none'
        @helper.pushDataSetting('close-button-visibility', 'autohide')
        expect(@helper.dataSettings['close-button-visibility']).toEqual(null)
