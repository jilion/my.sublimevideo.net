describe 'Asset', ->

  describe 'MySublimeVideo.Models.Asset', ->
    beforeEach ->
      @asset = new MySublimeVideo.Models.Asset

    describe 'srcIsEmpty()', ->
      it 'returns true when empty', ->
        @asset.set(src: '')
        expect(@asset.srcIsEmpty()).toBeTruthy()

      it 'returns false when not empty and not an URL', ->
        @asset.set(src: 'test')
        expect(@asset.srcIsEmpty()).toBeFalsy()

      it 'returns false when an URL', ->
        @asset.set(src: 'http://test.com/foo/bar?a=b')
        expect(@asset.srcIsEmpty()).toBeFalsy()

    describe 'srcIsUrl()', ->
      it 'returns false when empty', ->
        @asset.set(src: '')
        expect(@asset.srcIsUrl()).toBeFalsy()

      it 'returns false when not empty and not an URL', ->
        @asset.set(src: 'test')
        expect(@asset.srcIsUrl()).toBeFalsy()

      it 'returns true when an URL', ->
        @asset.set(src: 'http://test.com/foo/bar?a=b')
        expect(@asset.srcIsUrl()).toBeTruthy()

    describe 'srcIsEmptyOrUrl()', ->
      it 'returns true when empty', ->
        @asset.set(src: '')
        expect(@asset.srcIsEmptyOrUrl()).toBeTruthy()

      it 'returns false when not empty and not an URL', ->
        @asset.set(src: 'test')
        expect(@asset.srcIsEmptyOrUrl()).toBeFalsy()

      it 'returns true when an URL', ->
        @asset.set(src: 'http://test.com/foo/bar?a=b')
        expect(@asset.srcIsEmptyOrUrl()).toBeTruthy()

    describe 'reset()', ->
      it 'resets the src, found and ratio attributes', ->
        @asset.set(src: 'test')
        @asset.set(found: false)
        @asset.set(ratio: 2)

        expect(@asset.get('src')).toEqual('test')
        expect(@asset.get('found')).toBeFalsy()
        expect(@asset.get('ratio')).toEqual(2)

        @asset.reset()

        expect(@asset.get('src')).toEqual('')
        expect(@asset.get('found')).toBeTruthy()
        expect(@asset.get('ratio')).toEqual(1)
