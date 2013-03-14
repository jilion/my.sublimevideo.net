describe 'MySublimeVideo.Models.Video', ->
  beforeEach ->
    @video = new MySublimeVideo.Models.Video

  describe 'setYouTubeId()', ->
    it 'handles proper ID', ->
      @video.setYouTubeId('abcd1234')

      expect(@video.get('youTubeId')).toEqual('abcd1234')

    it 'handles YouTube long URL (1)', ->
      @video.setYouTubeId('http://youtube.com/watch?v=abcd1234')

      expect(@video.get('youTubeId')).toEqual('abcd1234')

    it 'handles YouTube long URL (2)', ->
      @video.setYouTubeId('http://www.youtube.com/watch?feature=em-subs_digest&v=abcd1234')

      expect(@video.get('youTubeId')).toEqual('abcd1234')

    it 'handles YouTube short URL', ->
      @video.setYouTubeId('http://youtu.be/abcd1234')

      expect(@video.get('youTubeId')).toEqual('abcd1234')

  describe 'setUid()', ->
    it 'accepts proper data-uid', ->
      @video.setUid('abcd-12_34')

      expect(@video.get('uid')).toEqual('abcd-12_34')
    it 'accepts proper data-uid with uppercase letters', ->
      @video.setUid('aBcD-12_34')

      expect(@video.get('uid')).toEqual('aBcD-12_34')

    it 'accepts 1 character UID', ->
      @video.setUid('a')

      expect(@video.get('uid')).toEqual('a')

    it 'accepts 64 character UID', ->
      @video.setUid('aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa')

      expect(@video.get('uid')).toEqual('aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa')

    it 'rejects empty UID', ->
      @video.setUid('')

      expect(@video.get('uid')).toEqual('')

    it 'rejects 64+ characters UID', ->
      expect(@video.setUid('aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa')).toBeFalsy()

      expect(@video.get('uid')).toEqual(undefined)

    it 'rejects UID with "|"', ->
      expect(@video.setUid('abcd|1234')).toBeFalsy()

      expect(@video.get('uid')).toEqual(undefined)

    it 'rejects UID with "."', ->
      expect(@video.setUid('abcd.1234')).toBeFalsy()

      expect(@video.get('uid')).toEqual(undefined)

  describe 'setKeepRatio()', ->
    it 'recalculate only height from width and ratio when keepRatio is set to true', ->
      @video.set(width: 500)
      @video.set(height: 250)
      @video.set(ratio: 0.5)

      @video.setWidth(500)

      expect(@video.get('width')).toEqual(500)
      expect(@video.get('height')).toEqual(250)

      @video.set(keepRatio: false)
      @video.set(height: 100)

      expect(@video.get('width')).toEqual(500)
      expect(@video.get('height')).toEqual(100)

      @video.setKeepRatio(true)

      expect(@video.get('width')).toEqual(500)
      expect(@video.get('height')).toEqual(250)

    it 'don\'t recalculate anything when keepRatio is set to false', ->
      @video.set(width: 500)
      @video.set(height: 250)
      @video.set(ratio: 0.5)

      @video.setWidth(250)

      expect(@video.get('width')).toEqual(250)
      expect(@video.get('height')).toEqual(125)

      @video.setKeepRatio(false)

      expect(@video.get('width')).toEqual(250)
      expect(@video.get('height')).toEqual(125)

  describe 'setWidth()', ->
    it 'sets width to 200 if it is not a number', ->
      @video.setWidth('a')

      expect(@video.get('width')).toEqual(200)

    it 'cast the given width to integer', ->
      @video.setWidth('250')

      expect(@video.get('width')).toEqual(250)

    it 'sets the given width casted to integer', ->
      @video.setWidth(250.4)

      expect(@video.get('width')).toEqual(250)

    it 'minimum is 200', ->
      @video.setWidth(50)

      expect(@video.get('width')).toEqual(200)

    it 'maximum is 1920', ->
      @video.setWidth(5000)

      expect(@video.get('width')).toEqual(1920)

    it 'sets the height if keepRatio is true', ->
      @video.set(height: 800, ratio: 0.5)
      @video.setWidth(500)

      expect(@video.get('height')).toEqual(250)

    it 'do not sets the height if the second argument is false', ->
      @video.set(height: 800, ratio: 0.5)
      @video.setWidth(500, false)

      expect(@video.get('height')).toEqual(800)

  describe 'setHeight()', ->
    it 'sets height to 100 if it is not a number', ->
      @video.setHeight('a')

      expect(@video.get('height')).toEqual(100)

    it 'cast the given height to integer', ->
      @video.setHeight('250')

      expect(@video.get('height')).toEqual(250)

    it 'sets the given height casted to integer', ->
      @video.setHeight(250.4)

      expect(@video.get('height')).toEqual(250)

    it 'minimum is 100', ->
      @video.setHeight(50)

      expect(@video.get('height')).toEqual(100)

    it 'maximum is 1080', ->
      @video.setHeight(9999)

      expect(@video.get('height')).toEqual(1080)

    it 'sets the width if keepRatio is true', ->
      @video.set(width: 800, ratio: 0.5)
      @video.setHeight(300)

      expect(@video.get('width')).toEqual(600)

    it 'do not sets the width if the second argument is false', ->
      @video.set(width: 800, ratio: 0.5)
      @video.setHeight(500, false)

      expect(@video.get('width')).toEqual(800)

  describe 'updateSetting()', ->
    beforeEach ->
      @kit = new MySublimeVideo.Models.Kit(settings: { sharing: { title: 'Bar Foo' } })

    it 'create the missing keys and set the value (1)', ->
      @video.updateSetting('sharing', 'title', 'Foo Bar', @kit)

      expect(@video.get('settings')).toEqual({ 'sharing': { 'title': 'Foo Bar' } })

    it 'create the missing keys and set the value (2)', ->
      @video.set(settings: { 'sharing': {} })
      @video.updateSetting('sharing', 'title', 'Foo Bar', @kit)

      expect(@video.get('settings')).toEqual({ 'sharing': { 'title': 'Foo Bar' } })

    it 'remove the value if it is the default', ->
      @video.set(settings: { 'sharing': { 'title': 'Foo Bar' } })
      @video.updateSetting('sharing', 'title', 'Bar Foo', @kit)

      expect(@video.get('settings')).toEqual({ 'sharing': {} })
