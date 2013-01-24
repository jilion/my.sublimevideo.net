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
      expect(@helper.getDataSettingName('initial', 'overlay_enable')).toEqual('initial-overlay-enable')

  describe 'processCheckBoxInput: (dataSettingName, currentValue, defaultValue)', ->
    describe 'options["forceSettings"] is false', ->
      beforeEach ->
        @video  = new MySublimeVideo.Models.Video
        @helper = new MySublimeVideo.Helpers.VideoTagHelper(@video)
        @helper.dataSettings = {}

      it 'set data setting to "true"', ->
        expect(@helper.processCheckBoxInput('fullmode-priority', true, false))
        expect(@helper.dataSettings['fullmode-priority']).toEqual('true')

      it 'set data setting to "false"', ->
        expect(@helper.processCheckBoxInput('fullmode-priority', false, true))
        expect(@helper.dataSettings['fullmode-priority']).toEqual('false')

      it 'do not set data setting to "true"', ->
        expect(@helper.processCheckBoxInput('fullmode-priority', true, true))
        expect(@helper.dataSettings['fullmode-priority']).toEqual(null)

      it 'do not set data setting to "false"', ->
        expect(@helper.processCheckBoxInput('fullmode-priority', false, false))
        expect(@helper.dataSettings['fullmode-priority']).toEqual(null)

    describe 'options["forceSettings"] is true', ->
      beforeEach ->
        @video  = new MySublimeVideo.Models.Video
        @helper = new MySublimeVideo.Helpers.VideoTagHelper(@video, forceSettings: true)
        @helper.dataSettings = {}

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
    beforeEach ->
      @video  = new MySublimeVideo.Models.Video
      @helper = new MySublimeVideo.Helpers.VideoTagHelper(@video)
      @helper.dataSettings = {}

    it 'push setting', ->
      @helper.pushDataSetting('sharing-buttons', 'facebook google+ twitter')
      expect(@helper.dataSettings['sharing-buttons']).toEqual('facebook google+ twitter')
